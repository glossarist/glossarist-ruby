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
      #
      # In V3, n-ary relations (PartitiveHyperedge, GenericHyperedge) are
      # per-file (see Glossarist::V3::RelationLoader). Each concept's
      # relations are looked up via the relations lookup passed here.
      # Pass an explicit `relations:` list when constructing the context
      # — the loader does not run on demand so the validator behaviour
      # is fully deterministic given the load.
      class ConceptContext
        attr_reader :concept, :file_name, :collection_context, :relations,
                    :concept_resolver

        # `concept_resolver` is an optional callable that takes a
        # ConceptRef and returns the resolved ManagedConcept (or nil).
        # Rules that need cross-concept lookups (e.g.,
        # ExternalConceptRule's dangling-external detection) use this.
        # When nil, those rules no-op.
        def initialize(concept, file_name:, collection_context:, relations: [],
                       concept_resolver: nil)
          @concept = concept
          @file_name = file_name
          @collection_context = collection_context
          @relations = Array(relations)
          @concept_resolver = concept_resolver
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
