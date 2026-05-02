# frozen_string_literal: true

module Glossarist
  class ResolutionAdapter
    class Route < ResolutionAdapter
      attr_reader :routes

      def initialize(routes = {})
        super()
        @routes = routes
      end

      def add(from:, to:)
        @routes[from] = to
      end

      def resolve(reference)
        return nil unless reference.ref_type == "urn"
        return nil unless routes.key?(reference.source)

        ConceptReference.new(
          term: reference.term,
          concept_id: reference.concept_id,
          source: routes[reference.source],
          ref_type: reference.ref_type,
        )
      end

      def remap(source)
        routes[source] || source
      end
    end
  end
end
