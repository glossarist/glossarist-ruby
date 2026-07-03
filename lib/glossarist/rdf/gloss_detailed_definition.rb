# frozen_string_literal: true

require "digest"
require "lutaml/model"

module Glossarist
  module Rdf
    class GlossDetailedDefinition < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :sources, GlossConceptSource, collection: true
      attribute :examples, GlossDetailedDefinition, collection: true

      rdf do
        namespace Namespaces::GlossaristNamespace, Namespaces::RdfNamespace

        subject { |d| "definition/#{GlossDetailedDefinition.deterministic_id(d)}" }

        types "gloss:DetailedDefinition"

        predicate :value, namespace: Namespaces::RdfNamespace, to: :content

        members :sources
        members :examples, link: "gloss:hasExample"
      end

      def self.deterministic_id(definition)
        Digest::MD5.hexdigest(definition.content.to_s)[0..11]
      end
    end
  end
end
