# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module Glossarist
  module Designations
    class Base < Model
      # @note This is not entirely aligned with agreed schema and may be
      #   changed.
      attr_accessor :designation

      attr_accessor :normative_status
      attr_accessor :geographical_area

      def self.from_h(hash)
        type = hash["type"]

        if type.nil? || /\w/ !~ type
          raise ArgumentError, "designation type is missing"
        end

        designation_subclass = SERIALIZED_TYPES[type]

        if self == Base
          # called on Base class, delegate it to proper subclass
          SERIALIZED_TYPES[type].from_h(hash)
        else
          # called on subclass, instantiate object
          unless SERIALIZED_TYPES[self] == type
            raise ArgumentError, "unexpected designation type: #{type}"
          end
          super(hash.reject { |k, _| k == "type" })
        end
      end
    end

    class Expression < Base
      attr_accessor :gender
      attr_accessor :part_of_speech
      attr_accessor :plurality
      attr_accessor :prefix
      attr_accessor :usage_info

      def to_h
        {
          "type" => "expression",
          "prefix" => prefix,
          "normative_status" => normative_status,
          "usage_info" => usage_info,
          "designation" => designation,
          "part_of_speech" => part_of_speech,
          "geographical_area" => geographical_area,
          "gender" => gender,
          "plurality" => plurality,
        }.compact
      end
    end

    class Symbol < Base
      attr_accessor :international

      def to_h
        {
          "type" => "symbol",
          "normative_status" => normative_status,
          "geographical_area" => geographical_area,
          "designation" => designation,
          "international" => international,
        }.compact
      end
    end

    # Bi-directional class-to-string mapping for STI-like serialization.
    SERIALIZED_TYPES = {
      Expression => "expression",
      Symbol => "symbol",
    }
    .tap { |h| h.merge!(h.invert) }
    .freeze
  end
end
