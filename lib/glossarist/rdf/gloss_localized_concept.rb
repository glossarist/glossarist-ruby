# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    class GlossLocalizedConcept < Lutaml::Model::Serializable
      attribute :concept_id, :string
      attribute :language_code, :string
      attribute :domain, :string
      attribute :entry_status, :string
      attribute :release, :string
      attribute :lineage_similarity, :integer
      attribute :script, :string
      attribute :system, :string
      attribute :designations, GlossDesignation, collection: true
      attribute :definitions, GlossDetailedDefinition, collection: true
      attribute :notes, GlossDetailedDefinition, collection: true
      attribute :examples, GlossDetailedDefinition, collection: true
      attribute :sources, GlossConceptSource, collection: true
      attribute :non_verb_reps, GlossNonVerbalRep, collection: true

      rdf do
        namespace Namespaces::GlossaristNamespace,
                  Namespaces::SkosNamespace,
                  Namespaces::SkosxlNamespace,
                  Namespaces::DctermsNamespace,
                  Namespaces::IsoThesNamespace,
                  Namespaces::RdfNamespace

        subject { |l| "concept/#{l.concept_id}/#{l.language_code}" }

        types "gloss:LocalizedConcept", "skos:Concept"

        predicate :language, namespace: Namespaces::DctermsNamespace, to: :language_code
        predicate :hasEntryStatus, namespace: Namespaces::GlossaristNamespace, to: :entry_status, as: :uri
        predicate :domain, namespace: Namespaces::GlossaristNamespace, to: :domain
        predicate :release, namespace: Namespaces::GlossaristNamespace, to: :release
        predicate :lineageSimilarity, namespace: Namespaces::GlossaristNamespace, to: :lineage_similarity
        predicate :script, namespace: Namespaces::GlossaristNamespace, to: :script
        predicate :conversionSystem, namespace: Namespaces::GlossaristNamespace, to: :system

        members :designations,
                link: ->(d) { GlossLocalizedConcept.skosxl_label_for(d) }
        members :definitions,
                link: "gloss:hasDefinition"
        members :notes,
                link: "gloss:hasNote"
        members :examples,
                link: "gloss:hasExample"
        members :sources,
                link: "gloss:hasSource"
        members :non_verb_reps,
                link: "gloss:hasNonVerbalRep"
      end

      def self.skosxl_label_for(designation)
        status = designation.normative_status.to_s.split("/").last
        case status
        when "preferred" then "skosxl:prefLabel"
        when "deprecated" then "skosxl:hiddenLabel"
        else "skosxl:altLabel"
        end
      end
    end
  end
end
