# frozen_string_literal: true

module Glossarist
  module Transforms
    class ConceptToSkosTransform
      def self.transform(managed_concept, options = {})
        new(managed_concept, options).build
      end

      def self.transform_document(concepts, options = {})
        Rdf::SkosVocabulary.new(
          id: options[:shortname] || "glossary",
          title: options[:title],
          concepts: concepts.map { |c| transform(c, options) },
        )
      end

      def initialize(managed_concept, options = {})
        @concept = managed_concept
        @options = options
      end

      def build
        Rdf::SkosConcept.new(
          code: concept_code,
          labels: build_labels,
          definitions: build_definitions,
          alt_labels: build_alt_labels,
          scope_notes: build_scope_notes,
          domain: build_domain,
          sources: build_sources,
          date_accepted: build_date_accepted,
        )
      end

      private

      attr_reader :concept, :options

      def concept_code
        concept.data&.id || concept.identifier
      end

      def build_labels
        each_localization.filter_map do |lang, l10n|
          term = l10n.preferred_terms&.first || l10n.terms&.first
          next unless term

          Rdf::LocalizedLiteral.new(
            value: term.designation.to_s,
            language_code: lang,
          )
        end
      end

      def build_alt_labels
        each_localization.flat_map do |lang, l10n|
          preferred_term = l10n.preferred_terms&.first || l10n.terms&.first
          (l10n.terms || []).reject do |t|
            t == preferred_term
          end.filter_map do |term|
            next unless term.designation

            Rdf::LocalizedLiteral.new(
              value: term.designation.to_s,
              language_code: lang,
            )
          end
        end
      end

      def build_definitions
        each_localization.filter_map do |lang, l10n|
          content = l10n.data&.definition&.first&.content
          next unless content

          Rdf::LocalizedLiteral.new(
            value: content.to_s,
            language_code: lang,
          )
        end
      end

      def build_scope_notes
        each_localization.filter_map do |lang, l10n|
          note = l10n.data&.notes&.first&.content
          next unless note

          Rdf::LocalizedLiteral.new(
            value: note.to_s,
            language_code: lang,
          )
        end
      end

      def build_domain
        l10n = concept.localizations.first
        l10n&.data&.domain
      end

      def build_sources
        each_localization.flat_map do |_lang, l10n|
          Array(l10n.data&.sources).select(&:authoritative?).filter_map do |src|
            origin = src.origin
            next unless origin

            origin.ref || origin.text
          end
        end.uniq
      end

      def build_date_accepted
        date = concept.date_accepted
        return unless date

        date.date&.iso8601
      end

      def each_localization
        return enum_for(:each_localization) unless block_given?

        concept.localizations.each do |l10n|
          lang = l10n.language_code || l10n.data&.language_code
          next unless lang

          yield lang, l10n
        end
      end
    end
  end
end
