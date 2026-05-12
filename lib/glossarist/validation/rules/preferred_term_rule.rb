# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class PreferredTermRule < Base
        def code = "GLS-301"
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

          concept.localizations.each do |l10n|
            lang = l10n.language_code || "unknown"
            terms = l10n.data&.terms || []
            next if terms.empty?
            next if terms.any? { |t| t.normative_status == "preferred" }

            issues << issue(
              "has #{terms.size} term(s) but none are preferred",
              code: code, severity: severity,
              location: "#{fname}/#{lang}",
              suggestion: "Set normative_status: preferred on the primary term",
            )
          end

          issues
        end
      end
    end
  end
end

