# frozen_string_literal: true

require_relative "base"

module Glossarist
  module Designation
    class Expression < Base
      attr_accessor :prefix
      attr_accessor :usage_info

      # List of grammar info.
      # @return [Array<GrammarInfo>]
      attr_reader :grammar_info

      def grammar_info=(grammar_info)
        @grammar_info = grammar_info.map { |g| GrammarInfo.new(g) }
      end

      # @todo Added to cater for current iev-data implementation,
      #   might be removed in the future.
      def self.from_h(hash)
        gender = hash.delete("gender") || hash.delete(:gender)
        number = hash.delete("plurality") || hash.delete(:plurality)
        part_of_speech = hash.delete("part_of_speech") || hash.delete(:part_of_speech)

        if gender || number || part_of_speech
          hash["grammar_info"] = [{
            "gender" => gender,
            "number" => number,
            part_of_speech => part_of_speech,
          }]
        end

        super
      end

      def to_h
        {
          "type" => "expression",
          "prefix" => prefix,
          "normative_status" => normative_status,
          "usage_info" => usage_info,
          "designation" => designation,
          "geographical_area" => geographical_area,
          "grammar_info" => grammar_info&.map(&:to_h),
        }.compact
      end
    end
  end
end
