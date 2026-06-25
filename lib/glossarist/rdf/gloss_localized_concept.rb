# frozen_string_literal: true

require "lutaml/model"
require "rdf"

module Glossarist
  module Rdf
    class GlossLocalizedConcept < Lutaml::Model::Serializable
      include EmitsExtraTriples

      SKOS_PREF_LABEL   = RDF::URI("http://www.w3.org/2004/02/skos/core#prefLabel")
      SKOS_ALT_LABEL    = RDF::URI("http://www.w3.org/2004/02/skos/core#altLabel")
      SKOS_HIDDEN_LABEL = RDF::URI("http://www.w3.org/2004/02/skos/core#hiddenLabel")
      SKOS_DEFINITION   = RDF::URI("http://www.w3.org/2004/02/skos/core#definition")
      SKOS_SCOPE_NOTE   = RDF::URI("http://www.w3.org/2004/02/skos/core#scopeNote")
      SKOS_EXAMPLE      = RDF::URI("http://www.w3.org/2004/02/skos/core#example")

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
      attribute :annotations, GlossDetailedDefinition, collection: true
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

        predicate :language, namespace: Namespaces::DctermsNamespace,
                             to: :language_code
        predicate :hasEntryStatus, namespace: Namespaces::GlossaristNamespace,
                                   to: :entry_status, uri_reference: true
        predicate :domain, namespace: Namespaces::GlossaristNamespace,
                           to: :domain
        predicate :release, namespace: Namespaces::GlossaristNamespace,
                            to: :release
        predicate :lineageSimilarity,
                  namespace: Namespaces::GlossaristNamespace, to: :lineage_similarity
        predicate :script, namespace: Namespaces::GlossaristNamespace,
                           to: :script
        predicate :conversionSystem,
                  namespace: Namespaces::GlossaristNamespace, to: :system

        members :designations,
                link: ->(d) { GlossLocalizedConcept.skosxl_label_for(d) }
        members :definitions,
                link: "gloss:hasDefinition"
        members :notes,
                link: "gloss:hasNote"
        members :examples,
                link: "gloss:hasExample"
        members :annotations,
                link: "gloss:hasAnnotation"
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

      # Hook invoked by Glossarist::Rdf::LutamlTurtleTransformExt.
      # Emits direct SKOS predicates alongside the reified SKOS-XL / gloss
      # forms, so consumers that only speak plain SKOS (no SKOS-XL) see the
      # labels, definitions, notes, and examples as plain literals.
      def emit_extra_triples(subject_uri, _mapping)
        lang = language_code.to_s if language_code && !language_code.to_s.empty?
        triples = []

        Array(designations).each do |desig|
          predicate = self.class.skos_label_predicate(desig)
          next unless predicate

          triples << RDF::Statement.new(subject_uri, predicate,
                                        self.class.rdf_literal(desig.designation, lang))
        end

        Array(definitions).each do |d|
          triples << RDF::Statement.new(subject_uri, SKOS_DEFINITION,
                                        self.class.rdf_literal(d.content, lang))
        end

        Array(notes).each do |n|
          triples << RDF::Statement.new(subject_uri, SKOS_SCOPE_NOTE,
                                        self.class.rdf_literal(n.content, lang))
        end

        Array(examples).each do |e|
          triples << RDF::Statement.new(subject_uri, SKOS_EXAMPLE,
                                        self.class.rdf_literal(e.content, lang))
        end

        triples
      end

      class << self
        def skos_label_predicate(designation)
          status = designation.normative_status.to_s.split("/").last
          case status
          when "preferred" then SKOS_PREF_LABEL
          when "deprecated" then SKOS_HIDDEN_LABEL
          else SKOS_ALT_LABEL
          end
        end

        def rdf_literal(value, lang)
          return RDF::Literal.new("") if value.nil?

          if lang
            RDF::Literal.new(value.to_s, language: lang)
          else
            RDF::Literal.new(value.to_s)
          end
        end
      end
    end
  end
end
