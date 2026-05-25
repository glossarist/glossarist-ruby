# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class LocalityCompletenessRule < Base
        def code = "GLS-308"
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

          all_origins(concept).each_with_index do |origin, idx|
            next unless origin
            next unless origin.locality

            loc = origin.locality
            if loc.type.nil? || loc.type.to_s.strip.empty?
              issues << issue(
                "source #{idx + 1} locality has no type",
                location: fname,
                suggestion: "Add locality type (e.g. 'clause')",
              )
            end

            if loc.reference_from.nil? || loc.reference_from.to_s.strip.empty?
              issues << issue(
                "source #{idx + 1} locality has no reference_from",
                location: fname,
                suggestion: "Add locality.reference_from (e.g. '3.1.3.10')",
              )
            end
          end

          issues
        end

        private

        def all_origins(concept)
          origins = []
          concept.localizations.each do |l10n|
            (l10n.data&.sources || []).each { |s| origins << s.origin if s.origin }
          end
          origins
        end
      end
    end
  end
end
