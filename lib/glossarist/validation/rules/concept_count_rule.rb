# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class ConceptCountRule < Base
        def code = "GLS-011"
        def category = :integrity
        def severity = "error"
        def scope = :collection

        def applicable?(context)
          context.metadata && context.metadata.concept_count
        end

        def check(context)
          expected = context.metadata.concept_count
          actual = context.concepts.size

          return [] if expected == actual

          [issue(
            "metadata.yaml concept_count is #{expected} " \
            "but found #{actual} concept files",
            code: code, severity: severity,
            location: "metadata.yaml",
            suggestion: "Update concept_count or add/remove concept files",
          )]
        end
      end
    end
  end
end

