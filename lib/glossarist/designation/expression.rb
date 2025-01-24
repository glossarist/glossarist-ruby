require_relative "base"
require_relative "grammar_info"

module Glossarist
  module Designation
    class Expression < Base
      attribute :prefix, :string
      attribute :usage_info, :string

      attribute :gender, :string
      attribute :plurality, :string
      attribute :part_of_speech, :string
      attribute :grammar_info, GrammarInfo, collection: true
      attribute :type, :string, default: -> { "expression" }

      yaml do
        map :type, to: :type, render_default: true
        map :prefix, to: :prefix
        map %i[usage_info usageInfo], to: :usage_info
        map %i[grammar_info grammarInfo], to: :grammar_info
      end

      def self.of_yaml(hash, options = {})
        gender = hash.delete("gender") || hash.delete(:gender)
        number = hash.delete("plurality") || hash.delete(:plurality)
        part_of_speech = hash.delete("part_of_speech") || hash.delete(:part_of_speech)

        if gender || number || part_of_speech
          hash["grammar_info"] = [{
            "gender" => gender,
            "number" => number,
            part_of_speech => part_of_speech,
          }.compact]
        end

        hash["type"] = "expression" unless hash["type"]

        super(hash, options)
      end
    end
  end
end
