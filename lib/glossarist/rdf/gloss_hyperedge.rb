# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for a PartitiveHyperedge (concept-model v3.1.0).
    #
    # Emits one `gloss:PartitiveHyperedge` subject per hyperedge with:
    #
    #   - gloss:comprehensive — IRI of the comprehensive concept
    #   - gloss:part          — IRI of each part concept (zero or more)
    #   - gloss:enumeration   — xsd:string ("closed" | "open")
    #   - gloss:hasPluralityMarker — xsd:string per marker ("double" |
    #                                "dashed"). One triple per marker.
    #   - gloss:hyperedgeContent   — xsd:string (omitted if absent)
    #
    # The hyperedge is anchored to the concept that carries it via
    # `gloss:hasHyperedge` (an inverse of `gloss:comprehensive`). The
    # subject URI is derived from the carrying concept's identifier
    # and the comprehensive's id, so it is stable across builds.
    class GlossHyperedge < Lutaml::Model::Serializable
      attribute :identifier, :string
      attribute :comprehensive_id, :string
      attribute :comprehensive_uri, :string
      attribute :part_uris, :string, collection: true
      attribute :enumeration, :string
      attribute :markers, :string, collection: true
      attribute :content, :hash

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |h| "hyperedge/#{h.identifier}/#{h.comprehensive_id}" }

        types "gloss:PartitiveHyperedge"

        predicate :comprehensive, namespace: Namespaces::GlossaristNamespace,
                                   to: :comprehensive_uri
        predicate :part, namespace: Namespaces::GlossaristNamespace,
                          to: :part_uris
        predicate :enumeration, namespace: Namespaces::GlossaristNamespace,
                                to: :enumeration
        predicate :hasPluralityMarker,
                  namespace: Namespaces::GlossaristNamespace,
                  to: :markers
        predicate :hyperedgeContent,
                  namespace: Namespaces::GlossaristNamespace,
                  to: :content
      end
    end
  end
end
