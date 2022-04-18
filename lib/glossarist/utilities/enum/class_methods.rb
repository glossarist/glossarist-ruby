# frozen_string_literal: true

module Glossarist
  module Utilities
    module Enum
      module ClassMethods
        # Hash to contain enums with their options
        # @example
        #   status: { registered_values: [ :active, :inactive ], options: { multiple: false } }
        def enums
          @enums ||= {}
        end

        def register_enum(name, values, options = {})
          values = standardize_values(values)

          enums[name] = { registered_values: values, options: options }

          register_type_accessor(name)

          values.each do |value|
            add_check_method(name, value)
            add_set_method(name, value)
          end
        end

        def registered_enums
          enums.keys
        end

        def valid_types(name)
          enums[name][:registered_values]
        end

        def type_options(name)
          enums[name][:options]
        end

        def register_type_reader(name)
          define_method(name) do
            if self.class.type_options(name)[:multiple]
              selected_type[name]
            else
              selected_type[name].first
            end
          end
        end

        def register_type_writer(name)
          define_method("#{name}=") do |type|
            select_type(name, type)
          end
        end

        # Adds a reader and writer for the type name given.
        def register_type_accessor(name)
          register_type_reader(name)
          register_type_writer(name)
        end

        def add_check_method(name, value)
          define_method("#{value}?") do
            !!selected_type[name]&.include?(value.to_sym)
          end
        end

        def add_set_method(name, value)
          define_method("#{value}=") do |input|
            if input
              select_type(name, value)
            else
              deselect_type(name, value)
            end
          end
        end

        def standardize_values(values)
          if values.is_a?(Array)
            values.map(&:to_sym)
          else
            [values.to_sym]
          end
        end
      end
    end
  end
end
