# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class DefinitionContentRule < Base
        def code = "GLS-300"
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
            (l10n.data&.definition || []).each_with_index do |d, idx|
              if d.content.nil? || d.content.strip.empty?
                issues << issue(
                  "definition #{idx + 1} has empty content",
                  code: code, severity: severity,
                  location: "#{fname}/#{lang}",
                  suggestion: "Add definition text or remove the empty entry",
                )
              end
            end
          end

          issues
        end
      end
    end
  end
end

