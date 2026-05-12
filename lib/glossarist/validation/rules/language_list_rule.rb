# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class LanguageListRule < Base
        def code = "GLS-012"
        def category = :integrity
        def severity = "warning"
        def scope = :collection

        def applicable?(context)
          declared = context.declared_languages
          declared.is_a?(Array) && declared.any?
        end

        def check(context)
          declared = Set.new(context.declared_languages)
          actual = Set.new(context.actual_languages)
          issues = []

          missing = declared - actual
          if missing.any?
            issues << issue(
              "declared languages not found in concepts: #{missing.sort.join(', ')}",
              code: code, severity: severity,
              suggestion: "Update the languages list or add missing localizations",
            )
          end

          extra = actual - declared
          if extra.any?
            issues << issue(
              "concepts use languages not declared: #{extra.sort.join(', ')}",
              code: code, severity: severity,
              suggestion: "Add these languages to the languages list in metadata",
            )
          end

          issues
        end
      end
    end
  end
end

