# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class LanguageCoverageRule < Base
        def code = "GLS-013"
        def category = :localization
        def severity = "warning"
        def scope = :concept

        def applicable?(context)
          declared = context.declared_languages
          declared.is_a?(Array) && declared.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          declared = context.declared_languages
          present = concept.localizations&.values&.map(&:language_code) || []
          missing = declared - present

          return [] if missing.empty?

          [issue(
            "missing localizations for declared languages: #{missing.join(', ')}",
            code: code, severity: severity,
            location: fname,
            suggestion: "Add localizations for: #{missing.join(', ')}",
          )]
        end
      end
    end
  end
end

