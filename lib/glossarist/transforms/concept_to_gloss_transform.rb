# frozen_string_literal: true

module Glossarist
  module Transforms
    # Transforms Glossarist domain model objects into ontology-faithful RDF
    # using lutaml-model serializable view classes.
    #
    # Creates GlossConcept/GlossLocalizedConcept/GlossDesignation instances
    # and delegates Turtle/JSON-LD serialization to lutaml-model.
    class ConceptToGlossTransform
      GLOSS  = Rdf::Namespaces::GlossaristNamespace.uri
      SKOS   = Rdf::Namespaces::SkosNamespace.uri
      XL     = Rdf::Namespaces::SkosxlNamespace.uri
      ISO    = Rdf::Namespaces::IsoThesNamespace.uri
      DCT    = Rdf::Namespaces::DctermsNamespace.uri
      RDF_NS = Rdf::Namespaces::RdfNamespace.uri

      REL_PROPERTY_MAP = Rdf::RelationshipPredicates::ALL_REL_PREDICATES
        .transform_values { |ns, name| ns[name] }
        .transform_keys(&:to_s)
        .freeze

      DATE_TYPE_MAP = {
        "accepted" => "#{GLOSS}status/accepted",
        "amended" => "#{GLOSS}status/amended",
        "retired" => "#{GLOSS}status/retired",
      }.freeze

      def self.transform(managed_concept, options = {})
        new(managed_concept, options).build
      end

      def self.transform_document(concepts, options = {})
        new(nil, options).build_document(concepts)
      end

      def initialize(managed_concept, options = {})
        @concept = managed_concept
        @options = options
      end

      def build
        build_gloss_concept(concept)
      end

      def build_document(concepts)
        gloss_concepts = concepts.map { |c| build_gloss_concept(c) }
        doc = Rdf::GlossDocument.new(concepts: gloss_concepts)
        Rdf::GlossDocument.to_turtle(doc)
      end

      def to_turtle(concepts_or_concept = nil)
        if concepts_or_concept.is_a?(Array)
          build_document(concepts_or_concept)
        else
          target = concepts_or_concept || @concept
          return "" unless target

          gc = build_gloss_concept(target)
          Rdf::GlossConcept.to_turtle(gc)
        end
      end

      def to_jsonld(concepts_or_concept = nil)
        if concepts_or_concept.is_a?(Array)
          gloss_concepts = concepts_or_concept.map do |c|
            build_gloss_concept(c)
          end
          doc = Rdf::GlossDocument.new(concepts: gloss_concepts)
          Rdf::GlossDocument.to_jsonld(doc)
        else
          target = concepts_or_concept || @concept
          return "" unless target

          gc = build_gloss_concept(target)
          Rdf::GlossConcept.to_jsonld(gc)
        end
      end

      def to_jsonl_line
        return "" unless @concept

        gc = build_gloss_concept(@concept)
        Rdf::GlossConcept.to_jsonld(gc)
      end

      private

      attr_reader :concept, :options

      def build_gloss_concept(managed_concept)
        identifier = managed_concept.data&.id || managed_concept.identifier

        localizations = managed_concept.localizations.each_value.map do |l10n|
          build_gloss_localized_concept(l10n, identifier)
        end

        rel_targets = Rdf::RelationshipPredicates.related_targets_by_type(
          managed_concept.related,
          Rdf::RelationshipPredicates::CONCEPT_REL_PREDICATES,
        )

        Rdf::GlossConcept.new(
          identifier: identifier.to_s,
          status: status_uri(managed_concept.status),
          localizations: localizations,
          sources: build_gloss_sources(managed_concept.data&.sources),
          domains: build_gloss_domains(managed_concept.data&.domains,
                                       identifier),
          dates: build_gloss_dates(managed_concept.dates, identifier),
          **rel_targets,
        )
      end

      def build_gloss_localized_concept(l10n, concept_id)
        lang = l10n.language_code
        data = l10n.data

        designations = Array(l10n.designations).each_with_index.map do |desig, idx|
          build_gloss_designation(desig, concept_id, lang, idx)
        end

        dd_attrs = if data
                     data.class.detailed_definition_fields.to_h do |field|
                       [field, build_gloss_definitions(data.public_send(field))]
                     end
                   else
                     { definition: [], notes: [], examples: [] }
                   end

        sources = build_gloss_sources(data&.sources)
        non_verb_reps = build_gloss_non_verbal_reps(l10n.non_verb_rep,
                                                    concept_id, lang)

        Rdf::GlossLocalizedConcept.new(
          concept_id: concept_id.to_s,
          language_code: lang,
          domain: data&.domain,
          entry_status: data&.entry_status ? "gloss:entstatus/#{data.entry_status}" : nil,
          release: data&.release,
          lineage_similarity: data&.lineage_source_similarity,
          script: data&.script,
          system: data&.system,
          designations: designations,
          **dd_attrs,
          sources: sources,
          non_verb_reps: non_verb_reps,
        )
      end

      def build_gloss_designation(desig, concept_id, lang, index)
        common_attrs = designation_common_attrs(desig, concept_id, lang, index)
        instance = designation_instance_for(desig, common_attrs, concept_id,
                                            lang, index)

        rel_targets = Rdf::RelationshipPredicates.designation_targets_by_type(
          desig.related,
          Rdf::RelationshipPredicates::DESIGNATION_ONLY_PREDICATES,
        )
        rel_targets.each do |attr_name, targets|
          instance.public_send(:"#{attr_name}=", targets) unless targets.empty?
        end
        instance
      end

      def designation_instance_for(desig, common_attrs, concept_id, lang, index)
        case desig
        when Designation::Abbreviation
          build_gloss_abbreviation(desig, common_attrs, concept_id, lang, index)
        when Designation::Expression
          build_gloss_expression(desig, common_attrs, concept_id, lang, index)
        when Designation::GraphicalSymbol
          Rdf::GlossGraphicalSymbol.new(common_attrs.merge(text: desig.text,
                                                           image: desig.image))
        when Designation::LetterSymbol
          Rdf::GlossLetterSymbol.new(common_attrs.merge(text: desig.text))
        when Designation::Symbol
          Rdf::GlossSymbol.new(common_attrs)
        else
          Rdf::GlossExpression.new(common_attrs)
        end
      end

      def designation_common_attrs(desig, concept_id, lang, index)
        norm_status = desig.normative_status
        {
          designation: desig.designation,
          normative_status: norm_status ? "gloss:norm/#{norm_status}" : nil,
          type: desig.type,
          language: desig.language || lang,
          script: desig.script,
          system: desig.system,
          international: desig.international,
          absent: desig.absent,
          term_type: desig.term_type ? "gloss:termtype/#{desig.term_type}" : nil,
          concept_id: concept_id.to_s,
          lang_code: (desig.language || lang).to_s,
          index: index.to_s,
          pronunciations: build_gloss_pronunciations(desig.pronunciation,
                                                     concept_id, lang, index),
          sources: build_gloss_sources(desig.sources),
        }
      end

      def build_gloss_abbreviation(desig, common_attrs, concept_id, lang, index)
        Rdf::GlossAbbreviation.new(common_attrs.merge(
                                     prefix: desig.prefix,
                                     usage_info: desig.usage_info,
                                     field_of_application: desig.field_of_application,
                                     acronym: desig.acronym,
                                     initialism: desig.initialism,
                                     truncation: desig.truncation,
                                     grammar_info: build_gloss_grammar_infos(
                                       desig.grammar_info, concept_id, lang, index
                                     ),
                                   ))
      end

      def build_gloss_expression(desig, common_attrs, concept_id, lang, index)
        Rdf::GlossExpression.new(common_attrs.merge(
                                   prefix: desig.prefix,
                                   usage_info: desig.usage_info,
                                   field_of_application: desig.field_of_application,
                                   grammar_info: build_gloss_grammar_infos(
                                     desig.grammar_info, concept_id, lang, index
                                   ),
                                 ))
      end

      def build_gloss_definitions(definitions)
        Array(definitions).map do |dd|
          Rdf::GlossDetailedDefinition.new(
            content: dd.content,
            sources: build_gloss_sources(dd.sources),
          )
        end
      end

      def build_gloss_sources(sources)
        Array(sources).map do |src|
          origin = src.origin ? build_gloss_citation(src.origin) : nil
          Rdf::GlossConceptSource.new(
            status: src.status ? "gloss:srcstatus/#{src.status}" : nil,
            type: src.type ? "gloss:srctype/#{src.type}" : nil,
            modification: src.modification,
            origin: origin,
          )
        end
      end

      def build_gloss_citation(citation)
        locality = citation.locality ? build_gloss_locality(citation.locality) : nil
        ref = citation.ref

        Rdf::GlossCitation.new(
          source: ref&.source,
          id: ref&.id,
          version: ref&.version,
          link: citation.link,
          locality: locality,
        )
      end

      def build_gloss_locality(loc)
        Rdf::GlossLocality.new(
          locality_type: loc.type,
          reference_from: loc.reference_from,
          reference_to: loc.reference_to,
        )
      end

      def build_gloss_pronunciations(pronunciations, concept_id, lang,
_desig_index)
        Array(pronunciations).each_with_index.map do |pron, idx|
          Rdf::GlossPronunciation.new(
            content: pron.content,
            language: pron.language,
            script: pron.script,
            country: pron.country,
            system: pron.system,
            concept_id: concept_id.to_s,
            lang_code: lang.to_s,
            index: idx.to_s,
          )
        end
      end

      def build_gloss_grammar_infos(grammar_infos, concept_id, lang,
desig_index)
        Array(grammar_infos).map do |gi|
          Rdf::GlossGrammarInfo.new(
            gender: Array(gi.gender).map { |g| "gloss:gender/#{g}" },
            number: Array(gi.number).map { |n| "gloss:number/#{n}" },
            part_of_speech: gi.part_of_speech,
            concept_id: concept_id.to_s,
            lang_code: lang.to_s,
            index: desig_index.to_s,
          )
        end
      end

      def build_gloss_non_verbal_reps(non_verb_reps, concept_id, lang)
        Array(non_verb_reps).each_with_index.map do |nvr, idx|
          Rdf::GlossNonVerbalRep.new(
            representation_type: nvr.type,
            representation_ref: nvr.ref,
            representation_text: nvr.text,
            sources: build_gloss_sources(nvr.sources),
            concept_id: concept_id.to_s,
            lang_code: lang.to_s,
            index: idx.to_s,
          )
        end
      end

      def build_gloss_domains(domains, concept_id)
        Array(domains).map do |ref|
          Rdf::GlossConceptReference.new(
            concept_id: ref.concept_id,
            source: ref.source,
            ref_type: ref.ref_type,
            urn: ref.urn,
            parent_id: concept_id.to_s,
          )
        end
      end

      def build_gloss_dates(dates, concept_id)
        Array(dates).map do |date|
          Rdf::GlossConceptDate.new(
            date_value: date.date&.to_s,
            date_type: DATE_TYPE_MAP[date.type] || "gloss:status/#{date.type}",
            concept_id: concept_id.to_s,
          )
        end
      end

      def status_uri(status)
        status ? "gloss:status/#{status}" : nil
      end
    end
  end
end
