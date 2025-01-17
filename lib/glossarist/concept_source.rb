module Glossarist
  class ConceptSource < Lutaml::Model::Serializable
    attribute :status, :string,
              values: Glossarist::GlossaryDefinition::CONCEPT_SOURCE_STATUSES
    attribute :type, :string,
              values: Glossarist::GlossaryDefinition::CONCEPT_SOURCE_TYPES
    attribute :origin, Citation
    attribute :modification, :string

    yaml do
      # TODO: change to `map [:ref, :origin], to: :origin
      #       when multiple key mapping is supported in lutaml-model
      map :origin, to: :origin
      map :status, to: :status
      map :type, to: :type
      map :modification, to: :modification
    end
  end
end
