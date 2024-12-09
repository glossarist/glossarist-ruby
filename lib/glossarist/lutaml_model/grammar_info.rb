module Glossarist
  module LutamlModel
    class GrammarInfo < Lutaml::Model::Serializable
      attribute :gender, :string, values: Glossarist::GlossaryDefinition::GRAMMAR_INFO_GENDERS, collection: true
      attribute :number, :string, values: Glossarist::GlossaryDefinition::GRAMMAR_INFO_NUMBERS, collection: true
      attribute :part_of_speech, :string

      Glossarist::GlossaryDefinition::GRAMMAR_INFO_BOOLEAN_ATTRIBUTES.each do |name|
        attribute name.to_sym, :boolean
      end

      yaml do
        map :gender, to: :gender
        map :number, to: :number
        map :part_of_speech, to: :part_of_speech, with: { to: :part_of_speech_to_hash, from: :part_of_speech_from_hash }

        Glossarist::GlossaryDefinition::GRAMMAR_INFO_BOOLEAN_ATTRIBUTES.each do |name|
          map name.to_sym, to: name.to_sym

          define_singleton_method("#{name}?") do
            !!instance_variable_get("@#{name}")
          end
        end
      end

      def part_of_speech=(pos)
        @part_of_speech = pos
        public_send("#{pos}=", true)
      end

      def part_of_speech_from_hash(model, value)
        # skip
      end

      def part_of_speech_to_hash(model, doc)
        doc["#{part_of_speech}"] = true if part_of_speech
      end
    end
  end
end
