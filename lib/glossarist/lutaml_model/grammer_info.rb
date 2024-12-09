module Glossarist
  module LutamlModel
    class GrammerInfo < Lutaml::Model::Serializable
      attribute :gender, :string, values: Glossarist::GlossaryDefinition::GRAMMAR_INFO_GENDERS, collection: true
      attribute :number, :string, values: Glossarist::GlossaryDefinition::GRAMMAR_INFO_NUMBERS, collection: true
      attribute :pos, :string
      attribute :boolean_attributes, :string, values: Glossarist::GlossaryDefinition::GRAMMAR_INFO_BOOLEAN_ATTRIBUTES

      yaml do
        map :gender, to: :gender
        map :number, to: :number
        map :pos, to: :pos
        map :boolean_attributes, to: :boolean_attributes
      end

      def part_of_speech=(pos)
        public_send("#{pos}=", pos)
      end

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
