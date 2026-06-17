# frozen_string_literal: true

module Glossarist
  # Abstract base for dataset-level non-verbal representation entities.
  #
  # Figures, Tables, and Formulas share common metadata: stable identity,
  # localized caption/description (accessibility), and provenance sources.
  # Each is authored once at the dataset level and referenced by any number
  # of concepts — the same pattern as bibliography entries.
  #
  # This is the dataset-level counterpart to NonVerbRep (ISO 10241-1 §6.5),
  # which remains the concept-owned inline form.
  #
  # Subclasses (Figure, Table, Formula) add type-specific content fields.
  class NonVerbalEntity < Lutaml::Model::Serializable
    attribute :id, :string
    attribute :identifier, :string
    attribute :caption, :hash
    attribute :description, :hash
    attribute :alt, :hash
    attribute :sources, ConceptSource, collection: true

    key_value do
      map :id, to: :id
      map :identifier, to: :identifier
      map :caption, to: :caption
      map :description, to: :description
      map :alt, to: :alt
      map :sources, to: :sources
    end

    # Find self by ID. Figure overrides for recursive subfigure search.
    #
    # @param target_id [String]
    # @return [NonVerbalEntity, nil]
    def find_by_id(target_id)
      id == target_id ? self : nil
    end

    # This entity's IDs. Figure overrides to include subfigure IDs.
    #
    # @return [Array<String>]
    def all_ids
      [id]
    end

    def self.from_file(path)
      return nil unless File.exist?(path)

      from_yaml(File.read(path, encoding: "utf-8"))
    end
  end
end
