# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module Glossarist
  class Model
    def self.new(params = {})
      return params if params.is_a?(self)

      super
    end

    def initialize(attributes = {})
      attributes.each_pair { |k, v| set_attribute(k, v) }
    end

    def set_attribute(name, value)
      public_send("#{name}=", value)
    rescue NoMethodError
      # adding support for camel case
      if name.match?(/[A-Z]/)
        name = snake_case(name.to_s).to_sym
        retry
      elsif Config.extension_attributes.include?(name)
        extension_attributes[name] = value
      else
        raise ArgumentError, "#{self.class.name} does not have " +
          "attribute #{name} defined or the attribute is read only."
      end
    end

    def self.from_h(hash)
      new(hash)
    end

    def snake_case(str)
      str.gsub(/([A-Z])/) { "_#{$1.downcase}" }
    end
  end
end
