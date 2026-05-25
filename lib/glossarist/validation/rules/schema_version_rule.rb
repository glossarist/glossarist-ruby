# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class SchemaVersionRule < Base
        def code = "GLS-010"
        def category = :schema
        def severity = "warning"
        def scope = :concept

        def applicable?(context)
          context.concept.is_a?(ManagedConcept)
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          version = concept.schema_version
          if version.nil? || version.to_s.strip.empty?
            issues << issue(
              "concept has no schema_version",
              location: fname,
              suggestion: "Add schema_version: \"3\" to the concept",
            )
          elsif version.to_s != "3"
            issues << issue(
              "concept has schema_version '#{version}', expected '3'",
              location: fname,
              suggestion: "Run schema migration to upgrade to version 3",
            )
          end

          issues
        end
      end
    end
  end
end
