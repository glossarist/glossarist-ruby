# frozen_string_literal: true

require_relative "base"

module Glossarist
  module Designation
    class Expression < Base
      attr_accessor :gender
      attr_accessor :part_of_speech
      attr_accessor :plurality
      attr_accessor :prefix
      attr_accessor :usage_info

      # List of grammar info.
      # @return [Array<GrammarInfo>]
      attr_accessor :grammar_info

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
  end
end
