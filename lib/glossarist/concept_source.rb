module Glossarist
  class ConceptSource < Lutaml::Model::Serializable
    attribute :id, :string
    attribute :status, :string,
              values: Glossarist::GlossaryDefinition::CONCEPT_SOURCE_STATUSES
    attribute :type, :string,
              values: Glossarist::GlossaryDefinition::CONCEPT_SOURCE_TYPES
    attribute :origin, Citation
    attribute :modification, :string
    attribute :sourced_from, Citation, collection: true

    key_value do
      map :id, to: :id
      map :origin, to: :origin
      map :status, to: :status
      map :type, to: :type
      map :modification, to: :modification
      map :sourced_from, to: :sourced_from
    end
  end
end
