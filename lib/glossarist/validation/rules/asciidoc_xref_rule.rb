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
            texts = extract_texts(l10n)

            texts.each do |text|
              next unless text
              refs = extractor.extract_from_text(text)
              refs.each do |ref|
                next unless ref.is_a?(BibliographicReference)
                next if context.bibliography_index.resolve?(ref.anchor)

                issues << issue(
                  "unresolved bibliography reference <<#{ref.anchor}>>",
                  code: code, severity: severity,
                  location: "#{fname}/#{lang}",
                  suggestion: "add '#{ref.anchor}' as a source, " \
                              "or verify it exists in bibliography.yaml",
                )
              end
            end
          end

          issues
        end

        private

        def extract_texts(l10n)
          texts = []
          (l10n.data&.definition || []).each { |d| texts << d.content if d.content }
          (l10n.data&.notes || []).each { |n| texts << n.content if n.content }
          (l10n.data&.examples || []).each { |e| texts << e.content if e.content }
          texts
        end
      end
    end
  end
end

