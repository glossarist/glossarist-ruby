# frozen_string_literal: true

module Glossarist
  class ResolutionAdapter
    class Bibliography < ResolutionAdapter
      attr_reader :source_id, :concepts

      def initialize(source_id, concepts)
        super()
        @source_id = source_id
        @concepts = concepts
      end

      def resolve(reference)
        return nil unless reference.is_a?(ConceptReference)
        return nil unless reference.source == @source_id

        concepts.by_id_and(reference.concept_id, reference.version)
      end
    end
  end
end
