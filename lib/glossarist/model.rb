# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module Glossarist
  class Model
    def initialize(attributes = {})
      attributes.each_pair { |k, v| set_attribute(k, v) }
    end

    def set_attribute(name, value)
      public_send("#{name}=", value)
    rescue NoMethodError
      raise ArgumentError, "#{self.class.name} does not have " +
        "attribute #{name} defined or the attribute is read only."
    end
  end
end
