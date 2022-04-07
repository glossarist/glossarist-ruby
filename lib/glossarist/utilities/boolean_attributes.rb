# frozen_string_literal: true

module Glossarist
  module Utilities
    module BooleanAttributes
      def self.included(base)
        base.extend(ClassMethods)
      end

      def self.extended(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def register_boolean_attributes(attributes)
          attributes.each do |attribute|
            register_boolean_attribute(attribute)
          end
        end

        def register_boolean_attribute(attribute)
          attr_reader attribute

          define_method("#{attribute}=") do |value|
            instance_variable_set("@#{attribute}", !!value)
          end

          define_method("#{attribute}?") do
            !!instance_variable_get("@#{attribute}")
          end
        end
      end
    end
  end
end
