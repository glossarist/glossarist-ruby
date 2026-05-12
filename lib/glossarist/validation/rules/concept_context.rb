# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
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
