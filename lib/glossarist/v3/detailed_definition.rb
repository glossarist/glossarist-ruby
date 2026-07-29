# frozen_string_literal: true

module Glossarist
  module V3
    class DetailedDefinition < Glossarist::DetailedDefinition
      attribute :sources, V3::ConceptSource, collection: true
      attribute :examples, V3::DetailedDefinition, collection: true,
                                                   initialize_empty: true
      attribute :type, :string,
                values: Glossarist::GlossaryDefinition::DEFINITION_TYPE_VALUES,
                default: -> { DefinitionType::DEFAULT }

      key_value do
        map :content, to: :content
        map :type, to: :type
        map :sources, to: :sources
        map :examples, to: :examples
      end
    end
  end
end
