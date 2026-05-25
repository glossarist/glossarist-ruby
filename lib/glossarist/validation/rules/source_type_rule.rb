# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class SourceEnumRule < Base
        def code = "GLS-202"
        def category = :schema
        def severity = "error"
        def scope = :concept

        VALID_TYPES = Glossarist::GlossaryDefinition::CONCEPT_SOURCE_TYPES
        VALID_STATUSES = Glossarist::GlossaryDefinition::CONCEPT_SOURCE_STATUSES

        def applicable?(context)
          context.concept.localizations&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          concept.localizations.flat_map(&:all_sources).each_with_index do |source, idx|
            unless VALID_TYPES.include?(source.type)
              issues << issue(
                "source #{idx + 1} has invalid type '#{source.type}'",
                code: "GLS-202", severity: severity,
                location: fname,
                suggestion: "Use one of: #{VALID_TYPES.join(', ')}",
              )
            end

            next unless source.status && !VALID_STATUSES.include?(source.status)

            issues << issue(
              "source #{idx + 1} has invalid status '#{source.status}'",
              code: "GLS-203", severity: severity,
              location: fname,
              suggestion: "Use one of: #{VALID_STATUSES.join(', ')}",
            )
          end

          issues
        end
      end
    end
  end
end
