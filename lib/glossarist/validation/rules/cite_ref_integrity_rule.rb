# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class CiteRefIntegrityRule < Base
        def code = "GLS-110"
        def category = :references
        def severity = "warning"
        def scope = :concept

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
          concept.all_sources.each do |source|
            next unless source.id

            seen[source.id] << source
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
          keys = cite_mention_keys(concept)
          return if keys.empty?

          known_ids = concept.all_sources.filter_map(&:id).to_set
          keys.each do |key|
            next if known_ids.include?(key)

            issues << issue(
              "inline {{cite:#{key}}} does not resolve to any source",
              code: "GLS-110", severity: severity,
              location: fname,
              suggestion: "add a source with id '#{key}' or fix the reference"
            )
          end
        end

        def cite_mention_keys(concept)
          extractor = ReferenceExtractor.new
          extractor.extract_from_managed_concept(concept)
            .select(&:cite?)
            .filter_map(&:concept_id)
        end
      end
    end
  end
end
