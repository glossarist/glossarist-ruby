# frozen_string_literal: true

module Glossarist
  # Abstract base for references to dataset-level non-verbal entities.
  #
  # FigureReference, TableReference, and FormulaReference all carry an
  # entity ID and an optional display override. They are produced both by
  # structural arrays (`figures: [id]` on ManagedConceptData) and by inline
  # mentions (`{{fig:id}}` in text).
  #
  # Includes the {Reference} protocol so mixed-collection validation rules
  # can iterate these alongside ConceptReference / BibliographicReference /
  # AssetReference without type-checking. All predicates default to false.
  class NonVerbalReference < Lutaml::Model::Serializable
    include Reference

    attribute :entity_id, :string
    attribute :display, :string

    def self.of_yaml(hash)
      return new(entity_id: hash) if hash.is_a?(String)

      new(
        entity_id: hash["ref"] || hash["id"] || hash[:ref] || hash[:id],
        display: hash["display"] || hash[:display],
      )
    end

    def dedup_key
      [self.class.name, entity_id]
    end
  end
end
