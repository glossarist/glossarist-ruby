# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class AuthoritativeSourceRule < Base
        def code = "GLS-306"
        def category = :quality
        def severity = "warning"
        def scope = :concept

        def applicable?(context)
          context.concept.localizations&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name

          all_sources = concept.localizations.flat_map(&:all_sources)

          return [] if all_sources.any? { |s| s.type == "authoritative" }

          [issue(
            "no authoritative source defined",
            code: code, severity: severity,
            location: fname,
            suggestion: "Add at least one source with type: authoritative"
          )]
        end
      end
    end
  end
end
