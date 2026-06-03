# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class AsciidocXrefRule < Base
        def code = "GLS-102"
        def category = :references
        def severity = "warning"
        def scope = :concept

        def applicable?(context)
          context.concept.localizations&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          extractor = ReferenceExtractor.new
          issues = []

          concept.localizations.each do |l10n|
            lang = l10n.language_code || "unknown"

            l10n.text_content.each do |text|
              next unless text

              extractor.extract_from_text(text).each do |ref|
                next unless ref.is_a?(BibliographicReference)
                next if context.bibliography_index.resolve?(ref.anchor)

                issues << issue(
                  "unresolved bibliography reference <<#{ref.anchor}>>",
                  code: code, severity: severity,
                  location: "#{fname}/#{lang}",
                  suggestion: "add '#{ref.anchor}' as a source, " \
                              "or verify it exists in bibliography.yaml"
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
