# frozen_string_literal: true

module Glossarist
  module Utilities
    module Enum
      module InstanceMethods
        def selected_type
          initialize_selected_type if @selected_type.nil?

          @selected_type
        end

        def select_type(type_name, values)
          values = if values.is_a?(Array)
                     values
                   else
                     [values]
                   end

          values.each do |value|
            select_type_value(type_name, value)
          end
        end

        def deselect_type(type_name, value)
          selected_type[type_name].delete(value)
        end

        private

        def select_type_value(type_name, value)
          if !value
            selected_type[type_name].clear
          elsif self.class.valid_types(type_name).include?(value.to_sym)
            selected_type[type_name].clear unless self.class.type_options(type_name)[:multiple]
            selected_type[type_name] << value.to_sym
          else
            raise(
              Glossarist::InvalidTypeError,
              "`#{value}` is not a valid #{type_name}. Supported #{type_name} are #{self.class.enums[type_name][:registered_values].to_a.join(", ")}"
            )
          end
        end

        def initialize_selected_type
          @selected_type = {}

          self.class.registered_enums.each do |type|
            @selected_type[type] = []
          end
        end
      end
    end
  end
end
