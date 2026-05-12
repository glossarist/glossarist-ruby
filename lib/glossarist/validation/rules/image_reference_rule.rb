# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class ImageReferenceRule < Base
        def code = "GLS-103"
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

          # Text-embedded image references (image::path[])
          concept.localizations.each do |l10n|
            lang = l10n.language_code || "unknown"
            texts = extract_texts(l10n)

            texts.each do |text|
              next unless text
              refs = extractor.extract_from_text(text)
              refs.each do |ref|
                next unless ref.is_a?(AssetReference)
                next if context.asset_index.resolve?(ref.path)

                issues << issue(
                  "unresolved image reference #{ref.path}",
                  code: "GLS-103", severity: severity,
                  location: "#{fname}/#{lang}",
                  suggestion: "add '#{ref.path}' to the dataset's images/ directory",
                )
              end
            end
          end

          # Model-level asset references (NonVerbRep, GraphicalSymbol)
          asset_refs = extractor.extract_asset_refs_from_concept(concept)
          asset_refs.each do |ref|
            next if context.asset_index.resolve?(ref.path)

            issues << issue(
              "unresolved asset reference #{ref.path}",
              code: "GLS-104", severity: "error",
              location: fname,
              suggestion: "add '#{ref.path}' to the dataset's images/ directory",
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

