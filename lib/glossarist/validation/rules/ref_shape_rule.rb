# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class RefShapeRule < Base
        def code = "GLS-305"
        def category = :schema
        def severity = "error"
        def scope = :concept

        def applicable?(context)
          context.concept.localizations&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          check_sources(concept, fname, issues)
          check_related(concept, fname, issues)

          issues
        end

        private

        def check_sources(concept, fname, issues)
          concept.localizations.flat_map(&:all_sources).each_with_index do |source, idx|
            origin = source.origin
            next unless origin

            ref = origin.ref
            if ref.nil?
              issues << issue(
                "source #{idx + 1} origin has nil ref (expected Citation::Ref hash)",
                location: fname,
                suggestion: "Set origin.ref to { source: ..., id: ... }",
              )
            elsif ref.source.nil? && ref.id.nil?
              issues << issue(
                "source #{idx + 1} origin.ref has neither source nor id",
                location: fname,
                suggestion: "Provide at least origin.ref.source or origin.ref.id",
              )
            end
          end
        end

        def check_related(concept, fname, issues)
          (concept.related || []).each_with_index do |rel, idx|
            ref = rel.ref
            next unless ref

            if ref.source.nil? && ref.id.nil?
              issues << issue(
                "related concept #{idx + 1} has empty ref (no source or id)",
                location: fname,
                suggestion: "Provide at least ref.source or ref.id",
              )
            end
          end
        end
      end
    end
  end
end
