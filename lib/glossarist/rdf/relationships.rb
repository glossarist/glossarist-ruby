# frozen_string_literal: true

module Glossarist
  module Rdf
    # Included by RDF view classes that carry variable-predicate relationships.
    #
    # Standard SKOS/iso-thes relationships (broader, exactMatch, etc.) and
    # glossarist-specific relationships (deprecates, compares, etc.) are
    # emitted as direct triples with the predicate determined at runtime
    # from REL_PROPERTY_MAP.
    module Relationships
      attr_reader :relationship_triples

      def relationship_triples=(pairs)
        @relationship_triples = Array(pairs)
      end
    end
  end
end
