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
            concept.localizations.each do |l10n|
              l10n.text_content.each do |text|
                next unless text

                extractor.extract_from_text(text).each do |ref|
                  referenced_paths.add(ref.path) if ref.is_a?(AssetReference)
                end
              end
            end

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
              suggestion: "Remove the image or reference it from a concept"
            )
          end

          issues
        end
      end
    end
  end
end
