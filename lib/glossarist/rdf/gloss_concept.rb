# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    class GlossConcept < Lutaml::Model::Serializable
      attribute :identifier, :string
      attribute :status, :string
      attribute :localizations, GlossLocalizedConcept, collection: true
      attribute :sources, GlossConceptSource, collection: true
      attribute :domains, GlossConceptReference, collection: true
      attribute :dates, GlossConceptDate, collection: true
      attribute :partitive_relations, GlossPartitiveRelation, collection: true

      RelationshipPredicates::CONCEPT_REL_PREDICATES.each_key do |type|
        attribute :"#{type}_targets", :string, collection: true
      end

      rdf do
        namespace Namespaces::GlossaristNamespace,
                  Namespaces::SkosNamespace,
                  Namespaces::DctermsNamespace,
                  Namespaces::SkosxlNamespace,
                  Namespaces::IsoThesNamespace,
                  Namespaces::RdfNamespace

        subject { |c| "concept/#{c.identifier}" }

        types "gloss:Concept", "skos:Concept"

        predicate :identifier, namespace: Namespaces::GlossaristNamespace,
                               to: :identifier
        predicate :hasStatus, namespace: Namespaces::GlossaristNamespace,
                              to: :status, uri_reference: true

        members :localizations,
                link: "gloss:hasLocalization"
        members :sources,
                link: "gloss:hasSource"
        members :domains,
                link: "gloss:hasDomain"
        members :dates,
                link: "gloss:hasDate"
        members :partitive_relations,
                link: "gloss:hasPartitiveRelation"

        RelationshipPredicates::CONCEPT_REL_PREDICATES.each do |type, (ns, name)|
          predicate name, namespace: ns, to: :"#{type}_targets",
                          uri_reference: true
        end
      end
    end

    class GlossDocument < Lutaml::Model::Serializable
      attribute :concepts, GlossConcept, collection: true
      attribute :figures, GlossFigure, collection: true
      attribute :tables, GlossTable, collection: true
      attribute :formulas, GlossFormula, collection: true

      rdf do
        namespace Namespaces::GlossaristNamespace,
                  Namespaces::SkosNamespace,
                  Namespaces::DctermsNamespace,
                  Namespaces::SkosxlNamespace,
                  Namespaces::IsoThesNamespace,
                  Namespaces::RdfNamespace

        members :concepts
        members :figures
        members :tables
        members :formulas
      end
    end
  end
end
