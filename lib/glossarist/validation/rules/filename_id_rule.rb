# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class FilenameIdRule < Base
        def code = "GLS-015"
        def category = :integrity
        def severity = "error"
        def scope = :concept

        def applicable?(context)
          context.gcr?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          expected_id = concept.data&.id&.to_s
          actual_name = fname.sub(/\.yaml\z/, "").sub(%r{\Aconcepts/}, "")

          return [] unless expected_id && expected_id != actual_name

          [issue(
            "filename '#{actual_name}' does not match concept id '#{expected_id}'",
            code: code, severity: severity,
            location: "concepts/#{fname}",
            suggestion: "Rename the entry or fix the concept id",
          )]
        end
      end
    end
  end
end

