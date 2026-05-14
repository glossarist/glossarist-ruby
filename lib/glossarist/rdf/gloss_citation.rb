# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    class GlossCitation < Lutaml::Model::Serializable
      attribute :text, :string
      attribute :source, :string
      attribute :id, :string
      attribute :version, :string
      attribute :link, :string
      attribute :locality, GlossLocality

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |c| "citation/#{GlossCitation.slug(c)}" }

        types "gloss:Citation"

        predicate :citationText, namespace: Namespaces::GlossaristNamespace, to: :text
        predicate :citationSource, namespace: Namespaces::GlossaristNamespace, to: :source
        predicate :citationId, namespace: Namespaces::GlossaristNamespace, to: :id
        predicate :citationVersion, namespace: Namespaces::GlossaristNamespace, to: :version
        predicate :citationLink, namespace: Namespaces::GlossaristNamespace, to: :link

        members :locality, link: "gloss:hasLocality"
      end

      def self.slug(citation)
        slug = [citation.source, citation.id].compact.join("/")
        slug = Digest::MD5.hexdigest(citation.text || "")[0..11] if slug.empty?
        slug
      end
    end
  end
end
