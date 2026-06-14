# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      # Shared context for concept-scoped validation rules.
      #
      # Provides lazy-memoized access to extracted references so that multiple
      # rules examining the same concept share one extraction pass (DRY,
      # single source of truth). Rules ask the context for references rather
      # than instantiating their own ReferenceExtractor.
      class ConceptContext
        attr_reader :concept, :file_name, :collection_context

        def initialize(concept, file_name:, collection_context:)
          @concept = concept
          @file_name = file_name
          @collection_context = collection_context
        end

        def concept_id
          @concept.data&.id&.to_s
        end

        # All references extracted from the concept's text fields
        # (definitions, notes, examples) via {{...}} mentions, <<xrefs>>,
        # and image::...[] references. Includes ConceptReference,
        # BibliographicReference, and AssetReference objects.
        # Memoized — extracted once per concept, shared across all rules.
        def references
          @references ||= ReferenceExtractor.new
            .extract_from_managed_concept(@concept)
        end

        # All asset references (NonVerbRep, GraphicalSymbol) extracted
        # from the concept's model attributes.
        # Memoized — extracted once per concept, shared across all rules.
        def asset_references
          @asset_references ||= ReferenceExtractor.new
            .extract_asset_refs_from_concept(@concept)
        end

        def bibliography_index
          @collection_context.bibliography_index
        end

        def asset_index
          @collection_context.asset_index
        end

        def concept_ids
          @collection_context.concept_ids
        end

        def declared_languages
          @collection_context.declared_languages
        end

        def metadata
          @collection_context.metadata
        end

        def gcr?
          @collection_context.gcr?
        end
      end
    end
  end
end
