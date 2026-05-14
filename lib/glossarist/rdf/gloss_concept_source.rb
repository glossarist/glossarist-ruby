# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    class GlossConceptSource < Lutaml::Model::Serializable
      attribute :status, :string
      attribute :type, :string
      attribute :modification, :string
      attribute :origin, GlossCitation

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |s| "source/#{GlossConceptSource.deterministic_id(s)}" }

        types "gloss:ConceptSource"

        predicate :sourceStatus, namespace: Namespaces::GlossaristNamespace, to: :status, as: :uri
        predicate :sourceType, namespace: Namespaces::GlossaristNamespace, to: :type, as: :uri
        predicate :modification, namespace: Namespaces::GlossaristNamespace, to: :modification

        members :origin, link: "gloss:sourceOrigin"
      end

      def self.deterministic_id(source)
        parts = [source.status, source.type, source.modification]
        origin = source.origin
        if origin
          parts << origin.text << origin.source << origin.id << origin.version << origin.link
        end
        Digest::MD5.hexdigest(parts.compact.join("|"))[0..11]
      end
    end
  end
end
