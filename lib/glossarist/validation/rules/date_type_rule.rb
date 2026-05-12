# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class DateTypeRule < Base
        def code = "GLS-205"
        def category = :schema
        def severity = "warning"
        def scope = :concept

        VALID_TYPES = Glossarist::GlossaryDefinition::CONCEPT_DATE_TYPES

        def applicable?(context)
          concept = context.concept
          (concept.dates&.any?) || concept.date_accepted
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          check_date_collection(concept.dates, fname, issues)

          if concept.date_accepted && concept.date_accepted.type
            validate_date_type(concept.date_accepted, "date_accepted", fname, issues)
          end

          issues
        end

        private

        def check_date_collection(dates, fname, issues)
          (dates || []).each_with_index do |date, idx|
            next unless date.type
            validate_date_type(date, "date #{idx + 1}", fname, issues)
          end
        end

        def validate_date_type(date, label, fname, issues)
          return if VALID_TYPES.include?(date.type.to_s)

          issues << issue(
            "#{label} has invalid type '#{date.type}'",
            location: fname,
            suggestion: "Use one of: #{VALID_TYPES.join(', ')}",
          )
        end
      end
    end
  end
end
