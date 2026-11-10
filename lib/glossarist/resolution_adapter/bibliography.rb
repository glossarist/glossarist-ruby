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

        # concepts is any Enumerable of ManagedConcepts (Array or
        # GlossaryStore); match the uuid or the data id, with version.
        concepts.find do |c|
          (c.uuid == reference.concept_id || c.data&.id == reference.concept_id) &&
            (reference.version.nil? || c.version == reference.version)
        end
      end
    end
  end
end
