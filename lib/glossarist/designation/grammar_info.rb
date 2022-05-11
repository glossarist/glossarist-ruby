# frozen_string_literal: true

require_relative "../utilities"

module Glossarist
  module Designation
    class GrammarInfo
      include Glossarist::Utilities::Enum
      include Glossarist::Utilities::BooleanAttributes
      include Glossarist::Utilities::CommonFunctions

      register_enum :gender, Glossarist::GlossaryDefinition::GRAMMAR_INFO_GENDERS, multiple: true
      register_enum :number, Glossarist::GlossaryDefinition::GRAMMAR_INFO_NUMBERS, multiple: true

      register_boolean_attributes Glossarist::GlossaryDefinition::GRAMMAR_INFO_BOOLEAN_ATTRIBUTES

      def initialize(options = {})
        sanitized_options(options).each do |attr, value|
          public_send("#{attr}=", value)
        end
      end

      def part_of_speech=(pos)
        public_send("#{pos}=", pos)
      end

      def to_h
        {
          "preposition" => preposition?,
          "participle" => participle?,
          "adj" => adj?,
          "verb" => verb?,
          "adverb" => adverb?,
          "noun" => noun?,
          "gender" => gender,
          "number" => number,
        }
      end

      private

      def sanitized_options(options)
        hash = symbolize_keys(options)
        slice_keys(hash, [
          :gender,
          :number,
          :preposition,
          :participle,
          :adj,
          :verb,
          :adverb,
          :noun,
          :part_of_speech,
        ])
      end
    end
  end
end
