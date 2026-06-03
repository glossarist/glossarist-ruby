# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      # Validates that every URN-format source in citations and references
      # follows a recognized scheme (iso, iec, itu, etc).
      class SourceUrnFormatRule < Base
        URN_RE = %r{\Aurn:([a-z0-9][a-z0-9-]{0,31}):(.+)\z}i

        KNOWN_SCHEMES = %w[
          iso iec itu iso:std:iso iso:std:iec
        ].freeze

        def code = "GLS-310"
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

          all_refs(concept).each_with_index do |ref_str, idx|
            next unless ref_str&.start_with?("urn:")

            match = URN_RE.match(ref_str)
            unless match
              issues << issue(
                "source #{idx + 1} has malformed URN '#{ref_str}'",
                location: fname,
                suggestion: "Fix the URN to follow RFC 8141 format",
              )
            end
          end

          issues
        end

        private

        def all_refs(concept)
          refs = []
          concept.localizations.each do |l10n|
            (l10n.data&.sources || []).each do |s|
              refs << s.origin&.ref&.source if s.origin&.ref&.source&.start_with?("urn:")
            end
          end
          (concept.data&.domains || []).each do |d|
            refs << d.urn if d.urn
          end
          (concept.related || []).each do |r|
            refs << r.ref&.source if r.ref&.source&.start_with?("urn:")
          end
          refs.compact
        end
      end
    end
  end
end
