# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class AuthoritativeSourceRule < Base
        def code = "GLS-306"
        def category = :quality
        def severity = "warning"
        def scope = :concept

        def applicable?(context)
          context.concept.localizations&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          all_sources = gather_all_sources(concept)

          return [] if all_sources.any? { |s| s.type == "authoritative" }

          [issue(
            "no authoritative source defined",
            code: code, severity: severity,
            location: fname,
            suggestion: "Add at least one source with type: authoritative",
          )]
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

