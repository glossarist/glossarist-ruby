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
          fname = context.file_name
          issues = []

          context.references.each do |ref|
            next unless ref.is_a?(BibliographicReference)
            next if context.bibliography_index.resolve?(ref.anchor)

            issues << issue(
              "unresolved bibliography reference <<#{ref.anchor}>>",
              code: code, severity: severity,
              location: fname,
              suggestion: "add '#{ref.anchor}' as a source, " \
                          "or verify it exists in bibliography.yaml"
            )
          end

          issues
        end
      end
    end
  end
end
