# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class UuidFormatRule < Base
        UUID_RE = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

        def code = "GLS-016"
        def category = :integrity
        def severity = "error"
        def scope = :concept

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          uuid = concept.uuid
          if uuid && !uuid.to_s.empty? && !UUID_RE.match?(uuid.to_s)
            issues << issue(
              "concept UUID '#{uuid}' is not valid UUID format",
              location: fname,
              suggestion: "Use a valid UUID (e.g. 0ce27901-02ce-531e-8ba5-fdb136139d1a)",
            )
          end

          issues
        end
      end
    end
  end
end
