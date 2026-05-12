# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class RelatedConceptRule < Base
        def code = "GLS-200"
        def category = :schema
        def severity = "error"
        def scope = :concept

        VALID_TYPES = Glossarist::GlossaryDefinition::RELATED_CONCEPT_TYPES

        def applicable?(context)
          context.concept.related&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          (concept.related || []).each_with_index do |rel, idx|
            unless VALID_TYPES.include?(rel.type)
              issues << issue(
                "related concept #{idx + 1} has invalid type '#{rel.type}'",
                code: code, severity: severity,
                location: fname,
                suggestion: "Use one of: #{VALID_TYPES.join(', ')}",
              )
            end
          end

          issues
        end
      end
    end
  end
end

