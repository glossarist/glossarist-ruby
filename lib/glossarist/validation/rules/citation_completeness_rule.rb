# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class CitationCompletenessRule < Base
        def code = "GLS-304"
        def category = :quality
        def severity = "warning"
        def scope = :concept

        def applicable?(context)
          context.concept.localizations&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          gather_all_sources(concept).each_with_index do |source, idx|
            origin = source.origin
            next unless origin

            if origin.text.nil? && origin.source.nil? && origin.id.nil?
              issues << issue(
                "source #{idx + 1} has empty origin (no text, source, or id)",
                code: "GLS-304", severity: severity,
                location: fname,
                suggestion: "Add at minimum an origin.text or origin.source + origin.id",
              )
            end

            next unless origin.structured? && origin.source.nil?

            issues << issue(
              "source #{idx + 1} is structured but missing source field",
              code: "GLS-304", severity: severity,
              location: fname,
              suggestion: "Add origin.source to the citation",
            )
          end

          issues
        end

        private

        def gather_all_sources(concept)
          sources = []
          concept.localizations.each do |l10n|
            (l10n.data&.sources || []).each { |s| sources << s }
            (l10n.data&.definition || []).each { |d| (d.sources || []).each { |s| sources << s } }
            (l10n.data&.notes || []).each { |n| (n.sources || []).each { |s| sources << s } }
            (l10n.data&.examples || []).each { |e| (e.sources || []).each { |s| sources << s } }
          end
          sources
        end
      end
    end
  end
end

