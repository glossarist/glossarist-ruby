# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class OrphanedImagesRule < Base
        def code = "GLS-021"
        def category = :references
        def severity = "warning"
        def scope = :collection

        def applicable?(context)
          context.asset_index.paths.any?
        end

        def check(context)
          extractor = ReferenceExtractor.new
          referenced_paths = Set.new

          context.concepts.each do |concept|
            # Text-embedded image refs
            concept.localizations.each do |l10n|
              texts = extract_texts(l10n)
              texts.each do |text|
                next unless text
                extractor.extract_from_text(text).each do |ref|
                  if ref.is_a?(AssetReference)
                    referenced_paths.add(ref.path)
                  end
                end
              end
            end

            # Model-level asset refs
            extractor.extract_asset_refs_from_concept(concept).each do |ref|
              referenced_paths.add(ref.path)
            end
          end

          issues = []
          context.asset_index.each_path do |path|
            next if referenced_paths.include?(path)

            issues << issue(
              "Orphaned image: #{path} (not referenced by any concept)",
              code: code, severity: severity,
              location: path,
              suggestion: "Remove the image or reference it from a concept",
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

