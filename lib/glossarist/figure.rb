# frozen_string_literal: true

module Glossarist
  # A dataset-level figure entity (ISO 10241-1 §6.5 — non-verbal representation).
  #
  # Figures are authored once at `datasets/{ds}/figures/{fig-id}.yaml` and
  # referenced by any number of concepts via stable ID — the same sharing
  # pattern as bibliography entries. This is the rich, shareable counterpart
  # to concept-owned NonVerbRep entries.
  #
  # A Figure may carry multiple image variants (SVG + PNG + dark/light) for
  # responsive rendering and accessibility. Composite figures use recursive
  # subfigures.
  #
  # Caption, description, and alt are localized (hash keyed by ISO 639 code).
  class Figure < NonVerbalEntity
    attribute :images, FigureImage, collection: true
    attribute :subfigures, Figure, collection: true

    key_value do
      map :id, to: :id
      map :identifier, to: :identifier
      map :caption, to: :caption
      map :description, to: :description
      map :alt, to: :alt
      map :images, to: :images
      map :sources, to: :sources
      map :subfigures, to: :subfigures
    end

    # Recursively search for a subfigure (or self) by ID.
    #
    # @param target_id [String] the figure or subfigure ID
    # @return [Figure, nil]
    def find_by_id(target_id)
      return self if id == target_id

      Array(subfigures).each do |sub|
        found = sub.find_by_id(target_id)
        return found if found
      end
      nil
    end

    # Collect this figure's ID and all descendant subfigure IDs.
    #
    # @return [Array<String>]
    def all_ids
      [id] + Array(subfigures).flat_map(&:all_ids)
    end
  end
end
