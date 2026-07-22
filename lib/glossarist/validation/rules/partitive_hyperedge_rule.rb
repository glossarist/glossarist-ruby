# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      # Validates semantic invariants of PartitiveHyperedge entries that
      # the model constructor does NOT enforce. Specifically:
      #
      #   - warning when `enumeration` was filled by lutaml-model's
      #     default proc (i.e. the source YAML omitted it) — author is
      #     *encouraged* to set explicitly per the design doc
      #   - error when markers contain values not in
      #     PLURALITY_MARKER_VALUES
      #
      # The model constructor already rejects empty comprehensive,
      # empty parts, self-loops, and (lutaml-model auto-dedupes
      # duplicate markers on enum-collection assignment, so no
      # explicit check is needed).
      class PartitiveHyperedgeRule < Base
        def code = "GLS-220"
        def category = :schema
        def severity = "error"
        def scope = :concept

        def applicable?(context)
          concept = context.concept
          return false unless concept.is_a?(V3::ManagedConcept)

          concept.partitive_hyperedges&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          return issues unless concept.is_a?(V3::ManagedConcept)

          concept.partitive_hyperedges.each_with_index do |he, idx|
            check_comprehensive(he, idx, fname, issues)
            check_parts(he, idx, fname, issues)
            check_markers(he, idx, fname, issues)
            check_enumeration_explicit(he, idx, fname, issues)
          end

          issues
        end

        private

        def check_comprehensive(he, idx, fname, issues)
          ref = he.comprehensive
          return if ref.is_a?(Glossarist::ConceptRef) && (ref.source || ref.id)

          issues << issue(
            "partitive_hyperedge #{idx + 1} has empty comprehensive",
            location: fname,
          )
        end

        def check_parts(he, idx, fname, issues)
          parts = Array(he.parts)
          if parts.empty?
            issues << issue(
              "partitive_hyperedge #{idx + 1} has no parts",
              location: fname,
            )
            return
          end

          parts.each_with_index do |part, pi|
            next if part.is_a?(Glossarist::ConceptRef) && (part.source || part.id)

            issues << issue(
              "partitive_hyperedge #{idx + 1} part #{pi + 1} has empty ref",
              location: fname,
            )
          end
        end

        def check_markers(he, idx, fname, issues)
          # `using_default?` reports whether an attribute was set by
          # the user (false) or filled by the default proc (true).
          # `markers` has no default, so absence yields nil/[] and
          # `using_default?(:markers)` is true. We still walk for
          # invalid values because `values:` is informational.
          Array(he.markers).each_with_index do |m, mi|
            unless Glossarist::GlossaryDefinition::PLURALITY_MARKER_VALUES.include?(m)
              issues << issue(
                "partitive_hyperedge #{idx + 1} marker #{mi + 1} has invalid value #{m.inspect}",
                location: fname,
              )
            end
          end
        end

        def check_enumeration_explicit(he, idx, fname, issues)
          # `using_default?(:enumeration)` is true iff the value was
          # NOT explicitly set by the caller (filled by default proc).
          return unless he.using_default?(:enumeration)

          issues << issue(
            "partitive_hyperedge #{idx + 1} has implicit enumeration (default '#{Glossarist::V3::PartitiveHyperedge::DEFAULT_ENUMERATION}')",
            severity: "warning",
            location: fname,
            suggestion: "Set 'enumeration: closed' or 'enumeration: open' explicitly",
          )
        end
      end
    end
  end
end
