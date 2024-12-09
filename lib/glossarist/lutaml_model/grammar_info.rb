module Glossarist
  module LutamlModel
    class GrammarInfo < Lutaml::Model::Serializable
      attribute :gender, :string, values: Glossarist::GlossaryDefinition::GRAMMAR_INFO_GENDERS
      attribute :number, :string, values: Glossarist::GlossaryDefinition::GRAMMAR_INFO_NUMBERS
      attribute :part_of_speech, :string
      attribute :participle, :boolean
      attribute :adj, :boolean
      attribute :verb, :boolean
      attribute :adverb, :boolean
      attribute :noun, :boolean
      attribute :preposition, :boolean

      yaml do
        map :gender, to: :gender
        map :number, to: :number
        map :preposition, to: :preposition
        map :participle, to: :participle
        map :adj, to: :adj
        map :verb, to: :verb
        map :adverb, to: :adverb
        map :noun, to: :noun
        map :part_of_speech, to: :part_of_speech, with: { to: :part_of_speech_to_hash, from: :part_of_speech_from_hash }
      end

      def part_of_speech=(pos)
        @part_of_speech = pos
        public_send("#{pos}=", true)
      end

      def part_of_speech_from_hash(model, value)
        # skip
      end

      def part_of_speech_to_hash(model, doc)
        doc["#{part_of_speech}"] = true
      end
    end
  end
end
