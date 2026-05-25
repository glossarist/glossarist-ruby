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
                  if ref.is_a?(AssetReference)
                    referenced_paths.add(ref.path)
                  end
                end
              end
            end

            extractor.extract_asset_refs_from_concept(concept).each do |ref|
              referenced_paths.add(ref.path)
            end
          end

          images_file = load_images_file(context)
          if images_file
            context.bibliography_index.entries.each_value do |entry|
              next unless entry[:source].is_a?(V3::ImageEntry)
              path = entry[:source].path
              referenced_paths.add(path) if path
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

        def load_images_file(context)
          return @images_file if defined?(@images_file)

          @images_file = V3::ImageFile.from_file(
            File.join(context.path, "images.yaml")
          )
        end
      end
    end
  end
end
