# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    class GlossDetailedDefinition < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :sources, GlossConceptSource, collection: true

      rdf do
        namespace Namespaces::GlossaristNamespace, Namespaces::RdfNamespace

        subject { |d| "definition/#{d.content.hash.abs}" }

        types "gloss:DetailedDefinition"

        predicate :value, namespace: Namespaces::RdfNamespace, to: :content

        members :sources
      end
    end
  end
end
