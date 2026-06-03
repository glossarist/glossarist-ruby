# frozen_string_literal: true

require "lutaml/model"
require "digest"

module Glossarist
  module Rdf
    # Unified RDF view for bibliographic citations and concept references.
    #
    # Replaces the former GlossCitation and GlossConceptReference classes.
    # Both model "a reference to an item within a collection":
    #   - Citation: collection=document series, item=document, position=clause
    #   - ConceptReference: collection=termbase, item=concept
    class GlossReference < Lutaml::Model::Serializable
      attribute :text, :string
      attribute :source, :string
      attribute :id, :string
      attribute :version, :string
      attribute :link, :string
      attribute :locality, GlossLocality
      attribute :ref_type, :string
      attribute :urn, :string
      attribute :term, :string
      attribute :parent_id, :string

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |r| GlossReference.slug(r) }

        types "gloss:Reference"

        predicate :citationText, namespace: Namespaces::GlossaristNamespace,
                                 to: :text
        predicate :source, namespace: Namespaces::GlossaristNamespace,
                           to: :source
        predicate :refId, namespace: Namespaces::GlossaristNamespace, to: :id
        predicate :version, namespace: Namespaces::GlossaristNamespace,
                            to: :version
        predicate :link, namespace: Namespaces::GlossaristNamespace, to: :link
        predicate :refType, namespace: Namespaces::GlossaristNamespace,
                            to: :ref_type
        predicate :urn, namespace: Namespaces::GlossaristNamespace, to: :urn
        predicate :term, namespace: Namespaces::GlossaristNamespace, to: :term
        members :locality, link: "gloss:hasLocality"
      end

      def self.slug(ref)
        slug = [ref.source, ref.id].compact.join("/")
        slug = Digest::MD5.hexdigest(ref.text || "")[0..11] if slug.empty?
        slug
      end
    end

    # Backward-compatible aliases
    GlossCitation = GlossReference
    GlossConceptReference = GlossReference
  end
end
