# frozen_string_literal: true

module Glossarist
  # Shared payload for every non-concept entity — entities that are NOT
  # concepts at all (Figure, Table, Formula), as opposed to non-verbal
  # designations OF concepts (NonVerbRep).
  #
  # Terminology alignment (PROMPT-NOW P3):
  #   - Non-verbal refers to the modality of expression (non-verbal
  #     designation: symbol, formula expression). PROPERTIES OF concepts.
  #   - Non-concept refers to entities that are NOT concepts at all
  #     (Figure, Table, Formula). STANDALONE dataset entities.
  #
  # The four attributes here are the common a11y + provenance payload
  # every non-concept entity carries, regardless of content type:
  #
  # - +caption+: localized short title (a11y / indexing).
  # - +description+: localized long description (a11y screen readers).
  # - +alt+: localized alternative text (a11y short screen-reader label).
  # - +sources+: bibliographic sources for the representation.
  #
  # Identity (+id+, +identifier+) belongs on subclasses that have it;
  # see SharedNonConceptEntity for the dataset-shared variant.
  class NonConceptEntity < Lutaml::Model::Serializable
    attribute :caption, :hash
    attribute :description, :hash
    attribute :alt, :hash
    attribute :sources, ConceptSource, collection: true

    key_value do
      map :caption, to: :caption
      map :description, to: :description
      map :alt, to: :alt
      map :sources, to: :sources
    end

    def find_by_id(_target_id)
      nil
    end

    def all_ids
      []
    end

    def self.from_file(path)
      return nil unless File.exist?(path)

      from_yaml(File.read(path, encoding: "utf-8"))
    end
  end

  # @deprecated Use NonConceptEntity instead. Kept for one release
  #   cycle to ease migration of downstream callers.
end
