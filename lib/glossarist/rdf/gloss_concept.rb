# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    class GlossConcept < Lutaml::Model::Serializable
      include Relationships

      attribute :identifier, :string
      attribute :status, :string
      attribute :localizations, GlossLocalizedConcept, collection: true
      attribute :sources, GlossConceptSource, collection: true
      attribute :domains, GlossConceptReference, collection: true
      attribute :dates, GlossConceptDate, collection: true

      rdf do
        namespace Namespaces::GlossaristNamespace,
                  Namespaces::SkosNamespace,
                  Namespaces::DctermsNamespace,
                  Namespaces::SkosxlNamespace,
                  Namespaces::IsoThesNamespace,
                  Namespaces::RdfNamespace

        subject { |c| "concept/#{c.identifier}" }

        types "gloss:Concept", "skos:Concept"

        predicate :identifier, namespace: Namespaces::GlossaristNamespace, to: :identifier
        predicate :hasStatus, namespace: Namespaces::GlossaristNamespace, to: :status, as: :uri

        members :localizations,
                link: "gloss:hasLocalization"
        members :sources,
                link: "gloss:hasSource"
        members :domains,
                link: "gloss:hasDomain"
        members :dates,
                link: "gloss:hasDate"
      end
    end

    class GlossDocument < Lutaml::Model::Serializable
      attribute :concepts, GlossConcept, collection: true

      rdf do
        namespace Namespaces::GlossaristNamespace,
                  Namespaces::SkosNamespace,
                  Namespaces::DctermsNamespace,
                  Namespaces::SkosxlNamespace,
                  Namespaces::IsoThesNamespace,
                  Namespaces::RdfNamespace

        members :concepts
      end
    end
  end
end
