# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class ConceptUriRule < Base
        def code = "GLS-014"
        def category = :structure
        def severity = "warning"
        def scope = :collection

        def applicable?(context)
          context.gcr? && context.metadata
        end

        def check(context)
          meta = context.metadata
          return [] if meta.uri_prefix && !meta.uri_prefix.strip.empty?

          [issue(
            "no concept URI prefix or template defined in metadata",
            code: code, severity: severity,
            location: "metadata.yaml",
            suggestion: "Add uri_prefix or concept_uri_template to metadata.yaml",
          )]
        end
      end
    end
  end
end
