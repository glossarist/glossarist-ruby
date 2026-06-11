# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class CiteRefIntegrityRule < Base
        def code = "GLS-110"
        def category = :references
        def severity = "warning"
        def scope = :concept

        CITE_MENTION_RE = /\{\{\s*cite:([^,}\s]+)[^}]*?\}\}/

        def applicable?(context)
          context.concept.localizations&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          check_unique_source_ids(concept, fname, issues)
          check_unresolved_mentions(concept, fname, issues)

          issues
        end

        private

        def check_unique_source_ids(concept, fname, issues)
          seen = Hash.new { |h, k| h[k] = [] }
          record = ->(source) { seen[source.id] << source if source.id }

          Array(concept.sources).each(&record)
          Array(concept.data&.sources).each(&record)
          concept.localizations.each_value do |l10n|
            Array(l10n.sources).each(&record)
            Array(l10n.terms).each do |term|
              Array(term.sources).each(&record)
            end
          end

          seen.each do |id, sources|
            next if sources.length <= 1

            issues << issue(
              "duplicate source id '#{id}' appears #{sources.length} times",
              code: "GLS-110", severity: severity,
              location: fname,
              suggestion: "source ids must be unique within a concept"
            )
          end
        end

        def check_unresolved_mentions(concept, fname, issues)
          mentions = find_cite_mentions(concept)
          return if mentions.empty?

          known_ids = collect_source_ids(concept)
          mentions.each do |mention|
            next if known_ids.include?(mention[:key])

            issues << issue(
              "inline {{cite:#{mention[:key]}}} does not resolve to any source",
              code: "GLS-110", severity: severity,
              location: fname,
              suggestion: "add a source with id '#{mention[:key]}' or fix the reference"
            )
          end
        end

        def find_cite_mentions(concept)
          mentions = []
          concept.localizations.each do |l10n|
            next unless l10n.is_a?(LocalizedConcept)

            l10n.text_content.each_with_index do |content, i|
              next unless content.is_a?(String)

              content.scan(CITE_MENTION_RE) do |captures|
                key = captures.first.to_s.strip
                mentions << { key: key, source: "text_content[#{i}]" } unless key.empty?
              end
            end
          end
          mentions
        end

        def collect_source_ids(concept)
          ids = Set.new
          record = ->(source) { ids << source.id if source.id }

          Array(concept.sources).each(&record)
          Array(concept.data&.sources).each(&record)
          concept.localizations.each_value do |l10n|
            Array(l10n.sources).each(&record)
            Array(l10n.terms).each do |term|
              Array(term.sources).each(&record)
            end
          end
          ids
        end
      end
    end
  end
end
