# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class ConceptIdRule < Base
        def code = "GLS-001"
        def category = :structure
        def scope = :concept

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          id = concept.data&.id
          unless id
            issues << issue("#{fname}: missing concept id",
                            code: code, severity: "error")
            return issues
          end

          issues
        end
      end
    end
  end
end

