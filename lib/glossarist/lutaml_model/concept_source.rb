module Glossarist
  module LutamlModel
    class ConceptSource < Lutaml::Model::Serializable
      attribute :status, :string, values: Glossarist::GlossaryDefinition::CONCEPT_SOURCE_STATUSES
      attribute :type, :string, values: Glossarist::GlossaryDefinition::CONCEPT_SOURCE_TYPES
      attribute :origin, Citation
      attribute :modification, :string

      alias_method :ref=, :origin=

      yaml do
        map :status, to: :status
        map :type, to: :type
        map :origin, to: :origin
        map :modification, to: :modification
      end
    end
  end
end
