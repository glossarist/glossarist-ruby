# frozen_string_literal: true

require "date"

module Glossarist
  module Validation
    module Rules
      class DateValidityRule < Base
        def code = "GLS-307"
        def category = :quality
        def severity = "warning"
        def scope = :concept

        def applicable?(context)
          concept = context.concept
          (concept.dates&.any?) || concept.date_accepted
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          (concept.dates || []).each_with_index do |date, idx|
            validate_date(date, "date #{idx + 1}", fname, issues)
          end

          if concept.date_accepted
            validate_date(concept.date_accepted, "date_accepted", fname, issues)
          end

          issues
        end

        private

        def validate_date(concept_date, label, fname, issues)
          date_value = concept_date.date

          if date_value.nil? && concept_date.type
            issues << issue(
              "#{label} has no date value (type: #{concept_date.type})",
              location: fname,
              suggestion: "Provide a valid ISO 8601 date (e.g. 2024-01-15)",
            )
            return
          end

          return if date_value.nil?

          str = date_value.respond_to?(:iso8601) ? date_value.iso8601 : date_value.to_s

          begin
            DateTime.parse(str)
          rescue ArgumentError, TypeError
            issues << issue(
              "#{label} has unparseable date value '#{str}'",
              location: fname,
              suggestion: "Use an ISO 8601 date format (e.g. 2024-01-15)",
            )
          end
        end
      end
    end
  end
end
