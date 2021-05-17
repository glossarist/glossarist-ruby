# frozen_string_literal: true

module Glossarist
  class Model
    # include ActiveModel::Model
    # include ActiveModel::Attributes

    attr_reader :attributes

    def initialize(attributes = {})
      @attributes = {}
      self.attributes = attributes
    end

    def self.attribute(name, type = nil, **)
      define_method(name) { @attributes[name] }

      define_method("#{name}=") do |v|
        v = type.call(v) if type
        @attributes[name] = v
      end
    end

    def attributes=(attr_hash)
      attr_hash.each_pair { |k,v| self.public_send "#{k}=", v }
    end

    def to_h
      attributes.to_h.transform_values { |v| serialize_attibute_value v }
    end

    def serialize_attibute_value(attr_value)
      case attr_value
      when Model then attr_value.to_h
      when Array then attr_value.map { |x| serialize_attibute_value(x) }
      # when Hash then attr_value.transform_values { | x|serialize_attibute_value(x) }
      else attr_value
      end
    end
  end
end
