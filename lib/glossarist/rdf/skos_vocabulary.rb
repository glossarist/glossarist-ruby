# frozen_string_literal: true

require "lutaml/turtle"
require "lutaml/jsonld"

module Glossarist
  module Rdf
    class SkosVocabulary < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :title, :string
      attribute :concepts, SkosConcept, collection: true

      rdf do
        namespace Namespaces::SkosNamespace, Namespaces::DctermsNamespace

        subject { |v| "https://glossarist.org/vocab/#{v.id}" }
        type "skos:ConceptScheme"

        predicate :prefLabel, namespace: Namespaces::SkosNamespace, to: :title

        members :concepts
      end
    end
  end
end
