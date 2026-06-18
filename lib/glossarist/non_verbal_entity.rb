# frozen_string_literal: true

module Glossarist
  # Shared payload for every non-verbal representation, whether it lives
  # inline on a concept (NonVerbRep) or as a dataset-shared file
  # (Figure / Table / Formula).
  #
  # The four attributes here are the common a11y + provenance payload every
  # non-verbal entity carries, regardless of content type or scope:
  #
  # - +caption+: localized short title (a11y / indexing).
  # - +description+: localized long description (a11y screen readers).
  # - +alt+: localized alternative text (a11y short screen-reader label).
  # - +sources+: bibliographic sources for the representation.
  #
  # Identity (+id+, +identifier+) belongs on subclasses that have it; see
  # SharedNonVerbalEntity for the dataset-shared variant.
  class NonVerbalEntity < Lutaml::Model::Serializable
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
end
