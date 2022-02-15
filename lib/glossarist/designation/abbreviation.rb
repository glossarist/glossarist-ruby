# frozen_string_literal: true

require_relative "expression"

module Glossarist
  module Designation
    class Abbreviation < Expression
      class InvalidTypeError < StandardError; end

      TYPES = [:truncation, :acronym, :initialism]

      attr_accessor :international
      attr_accessor :type

      TYPES.each do |type|
        define_method("#{type}?") do
          @type == type
        end

        define_method("#{type}=") do |abbreviation_type|
          @type = abbreviation_type ? type : nil
        end
      end

      def type=(type)
        if TYPES.include?(type.to_sym)
          @type = type.to_sym
        else
          raise InvalidTypeError, "`#{type}` is not a valid type. Supported types are #{TYPES}"
        end
      end

      def to_h
        super().merge({
          "type" => @type.to_s,
          "international" => international,
        }).compact
      end
    end
  end
end
