# frozen_string_literal: true

require_relative "../utilities"

module Glossarist
  module Designation
    class GrammarInfo
      include Glossarist::Utilities::Enum
      include Glossarist::Utilities::BooleanAttributes

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

      # Hash#transform_keys is not available in Ruby 2.4
      # so we have to do this ourselves :(
      # symbolize hash keys
      def symbolize_keys(hash)
        result = {}
        hash.each_pair do |key, value|
          result[key.to_sym] = value
        end
        result
      end

      # Hash#slice is not available in Ruby 2.4
      # so we have to do this ourselves :(
      # slice hash keys
      def slice_keys(hash, keys)
        result = {}
        keys.each do |key|
          result[key] = hash[key] if hash.key?(key)
        end
        result
      end
    end
  end
end
