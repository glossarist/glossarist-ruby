# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    class GlossConceptSource < Lutaml::Model::Serializable
      attribute :status, :string
      attribute :type, :string
      attribute :modification, :string
      attribute :origin, GlossCitation
      attribute :sourced_from, GlossCitation, collection: true

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |s| "source/#{GlossConceptSource.deterministic_id(s)}" }

        types "gloss:ConceptSource"

        predicate :sourceStatus, namespace: Namespaces::GlossaristNamespace,
                                 to: :status, uri_reference: true
        predicate :sourceType, namespace: Namespaces::GlossaristNamespace,
                               to: :type, uri_reference: true
        predicate :modification, namespace: Namespaces::GlossaristNamespace,
                                 to: :modification

        members :origin, link: "gloss:sourceOrigin"
        members :sourced_from, link: "gloss:sourcedFrom"
      end

      def self.deterministic_id(source)
        parts = [source.status, source.type, source.modification]
        origin = source.origin
        if origin
          parts << origin.source << origin.id << origin.version << origin.link
        end
        Array(source.sourced_from).each do |sf|
          parts << sf&.source << sf&.id << sf&.version << sf&.link
        end
        Digest::MD5.hexdigest(parts.compact.join("|"))[0..11]
      end
    end
  end
end
