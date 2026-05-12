# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class OrphanedBibliographyRule < Base
        def code = "GLS-020"
        def category = :references
        def severity = "warning"
        def scope = :collection

        def applicable?(context)
          context.bibliography_index.entries.any?
        end

        def check(context)
          extractor = ReferenceExtractor.new
          bib_index = context.bibliography_index
          referenced_anchors = Set.new

          context.concepts.each do |concept|
            concept.localizations.each do |l10n|
              texts = extract_texts(l10n)
              texts.each do |text|
                next unless text
                extractor.extract_from_text(text).each do |ref|
                  if ref.is_a?(BibliographicReference)
                    referenced_anchors.add(ref.anchor)
                  end
                end
              end
            end
          end

          issues = []
          bib_index.each_entry do |entry|
            next if referenced_anchors.any? { |a| bib_index.resolve?(a) }

            anchor = entry[:anchor]
            issues << issue(
              "Orphaned bibliography entry: '#{anchor}'",
              code: code, severity: severity,
              location: "bibliography.yaml",
              suggestion: "Remove the entry or reference it from a concept",
            )
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

