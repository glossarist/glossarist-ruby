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
          fname = context.file_name
          issues = []

          context.references.each do |ref|
            next unless ref.is_a?(AssetReference)
            next if context.asset_index.resolve?(ref.path)

            issues << issue(
              "unresolved image reference #{ref.path}",
              code: "GLS-103", severity: severity,
              location: fname,
              suggestion: "add '#{ref.path}' to the dataset's images/ directory"
            )
          end

          context.asset_references.each do |ref|
            next if context.asset_index.resolve?(ref.path)

            issues << issue(
              "unresolved asset reference #{ref.path}",
              code: "GLS-104", severity: "error",
              location: fname,
              suggestion: "add '#{ref.path}' to the dataset's images/ directory"
            )
          end

          issues
        end
      end
    end
  end
end
