# frozen_string_literal: true

require "set"

module Glossarist
  module Utilities
    module Enum
      module ClassMethods
        def add_inheritable_attribute(attribute)
          @inheritable_attributes ||= Set[:inheritable_attributes]
          @inheritable_attributes << attribute
        end

        def inherited(subclass)
          @inheritable_attributes.each do |inheritable_attribute|
            instance_var = "@#{inheritable_attribute}"
            subclass.instance_variable_set(instance_var, instance_variable_get(instance_var))
          end
        end

        def enums
          @enums ||= EnumCollection.new
        end

        def register_enum(name, values, options = {})
          values = standardize_values(values)

          enums.add(name, values, options)

          add_inheritable_attribute(:enums)
          register_type_accessor(name)

          values.each do |value|
            register_check_method(name, value)
            register_set_method(name, value)
          end
        end

        def registered_enums
          enums.registered_enums
        end

        def valid_types(name)
          enums.valid_types(name)
        end

        def type_options(name)
          enums.type_options(name)
        end

        def register_type_reader(name)
          define_method(name) do
            if self.class.type_options(name)[:multiple]
              selected_type[name].map(&:to_s)
            else
              selected_type[name].first&.to_s
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

        def register_check_method(name, value)
          define_method("#{value}?") do
            !!selected_type[name]&.include?(value.to_sym)
          end
        end

        def register_set_method(name, value)
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
