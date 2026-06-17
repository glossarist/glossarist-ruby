# frozen_string_literal: true

module Glossarist
  module Collections
    # Generic collection for dataset-level non-verbal entities
    # (Figure, Table, Formula). Provides by_id lookup across top-level
    # entities and recursive subfigures (for Figure).
    #
    # Subclasses declare the entity type via `instances`.
    class NonVerbalCollection < Lutaml::Model::Collection
      # Find an entity by ID, searching recursively (Figure subfigures).
      #
      # @param id [String] the entity or sub-entity ID
      # @return [NonVerbalEntity, nil]
      def by_id(target_id)
        entries.each do |entity|
          found = entity.find_by_id(target_id)
          return found if found
        end
        nil
      end

      # All entity IDs including sub-entity IDs (for Figure subfigures).
      #
      # @return [Set<String>]
      def ids
        Set.new(entries.flat_map(&:all_ids).compact)
      end

      # Check if an entity with the given ID exists.
      #
      # @param id [String]
      # @return [Boolean]
      def exists?(id)
        !by_id(id).nil?
      end

      # Store an entity.
      #
      # @param entity [NonVerbalEntity]
      def store(entity)
        entries << entity
      end
      alias :<< :store

      def entries
        @entries ||= []
      end
    end
  end
end
