# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class TermsPresenceRule < Base
        def code = "GLS-005"
        def category = :structure
        def severity = "error"
        def scope = :concept

        def applicable?(context)
          context.concept.localizations&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          concept.localizations.each do |l10n|
            lang = l10n.language_code || "unknown"
            terms = l10n.data&.terms || []
            next unless terms.empty?

            issues << issue(
              "#{fname}/#{lang}: must have at least 1 term",
              code: code, severity: severity,
              location: "#{fname}/#{lang}",
              suggestion: "Add at least one term/designation to this localization",
            )
          end

          issues
        end
      end
    end
  end
end
