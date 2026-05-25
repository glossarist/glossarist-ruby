# frozen_string_literal: true

# Extends Lutaml::Rdf::Mapping with support for multiple rdf:type values.
#
# Usage in rdf do blocks:
#   type "gloss:Concept"                    # single type (original API)
#   types "gloss:Concept", "skos:Concept"   # multiple types (new API)
module Lutaml
  module Rdf
    class Mapping
      attr_writer :namespace_set, :rdf_subject, :rdf_type, :rdf_predicates,
                  :rdf_members

      def types(*values)
        @rdf_types = values.flatten.map(&:to_s)
      end

      def rdf_types
        if defined?(@rdf_types) && @rdf_types
          @rdf_types
        elsif @rdf_type
          [@rdf_type.to_s]
        else
          []
        end
      end

      def rdf_types=(values)
        @rdf_types = values
      end

      def has_types_or_predicates?
        rdf_types.any? || rdf_predicates.any?
      end
    end
  end
end
