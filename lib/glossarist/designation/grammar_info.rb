module Glossarist
  module Designation
    class GrammarInfo < Lutaml::Model::Serializable
      attribute :gender, :string,
                values: Glossarist::GlossaryDefinition::GRAMMAR_INFO_GENDERS, collection: true
      attribute :number, :string,
                values: Glossarist::GlossaryDefinition::GRAMMAR_INFO_NUMBERS, collection: true
      attribute :part_of_speech, :string,
                values: Glossarist::GlossaryDefinition::GRAMMAR_INFO_BOOLEAN_ATTRIBUTES

      yaml do
        map :gender, to: :gender
        map :number, to: :number

        map %i[part_of_speech partOfSpeech], with: { to: :part_of_speech_to_yaml, from: :part_of_speech_from_yaml }
        Glossarist::GlossaryDefinition::GRAMMAR_INFO_BOOLEAN_ATTRIBUTES.each do |bool_attr|
          map bool_attr,
              with: { to: :"part_of_speech_#{bool_attr}_to_yaml",
                      from: :"part_of_speech_#{bool_attr}_from_yaml" }
        end
      end

      def part_of_speech_from_yaml(model, value)
        model.part_of_speech = value
      end

      def part_of_speech_to_yaml(model, doc); end

      Glossarist::GlossaryDefinition::GRAMMAR_INFO_BOOLEAN_ATTRIBUTES.each do |bool_attr|
        define_method(:"part_of_speech_#{bool_attr}_from_yaml") do |model, value|
          model.public_send("#{bool_attr}=", value)
        end

        define_method(:"part_of_speech_#{bool_attr}_to_yaml") do |model, doc|
          doc[bool_attr] = model.public_send("#{bool_attr}?")
        end
      end
    end
  end
end
