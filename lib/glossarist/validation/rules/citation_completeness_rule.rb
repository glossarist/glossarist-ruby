# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class CitationCompletenessRule < Base
        def code = "GLS-304"
        def category = :quality
        def severity = "warning"
        def scope = :concept

        def applicable?(context)
          context.concept.localizations&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          concept.localizations.flat_map(&:all_sources).each_with_index do |source, idx|
            origin = source.origin
            next unless origin

            ref = origin.ref
            if ref.nil? || (ref.source.nil? && ref.id.nil?)
              issues << issue(
                "source #{idx + 1} has empty origin (no ref source or id)",
                code: "GLS-304", severity: severity,
                location: fname,
                suggestion: "Add at minimum an origin.ref with source or id"
              )
            end
          end

          issues
        end
      end
    end
  end
end
