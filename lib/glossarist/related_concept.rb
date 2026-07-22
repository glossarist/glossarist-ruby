# frozen_string_literal: true

module Glossarist
  class RelatedConcept < Lutaml::Model::Serializable
    attribute :content, :hash
    attribute :type, :string,
              values: Glossarist::GlossaryDefinition::RELATED_CONCEPT_TYPES
    attribute :ref, ConceptRef

    key_value do
      map :content, to: :content
      map :type, to: :type
      map :ref, to: :ref
    end
  end
end
