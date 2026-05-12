# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class ConceptStatusRule < Base
        def code = "GLS-201"
        def category = :schema
        def severity = "error"
        def scope = :concept

        VALID_STATUSES = Glossarist::GlossaryDefinition::CONCEPT_STATUSES

        def applicable?(context)
          !context.concept.status.nil?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          status = concept.status

          return [] if VALID_STATUSES.include?(status)

          [issue(
            "invalid concept status '#{status}'",
            code: code, severity: severity,
            location: fname,
            suggestion: "Use one of: #{VALID_STATUSES.join(', ')}",
          )]
        end
      end
    end
  end
end

