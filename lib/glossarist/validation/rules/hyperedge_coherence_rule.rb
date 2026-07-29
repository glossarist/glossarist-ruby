# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      # Validates semantic invariants of n-ary relation entries
      # (PartitiveHyperedge, GenericHyperedge) that the model constructor
      # does NOT enforce. The relations are passed in via the
      # ConceptContext (per-file storage — see Glossarist::V3::RelationLoader).
      #
      # Checks:
      #   - error when a relation has fewer than 2 members
      #     (ISO 704: "two or more"; single binary should use a
      #     has_part edge instead)
      #   - error when two relations share the same comprehensive
      #     AND the same non-empty criterion (duplicate decomposition;
      #     ISO 12620 coordinate-concept coherence)
      #   - warning when a relation has no criterion (cannot
      #     distinguish from siblings sharing the comprehensive)
      #   - warning when a member's presence or count deviates from
      #     the defaults (required / exactly_one) — encourages an
      #     explicit choice rather than an accidental non-default
      #   - error when ExternalConcept (status: external) lacks
      #     at least one designation
      #
      # The model constructor already rejects empty comprehensive,
      # empty members list, self-loops, invalid enum values, and
      # the optional + at_least_one combination.
      class HyperedgeCoherenceRule < Base
        DEFAULT_PRESENCE = "required"
        DEFAULT_COUNT = "exactly_one"

        # Stable identifier for downstream issue trackers / config.
        # Originally assigned when the rule was partitive-only; kept
        # after the rename to GenericHyperedge + n-ary generalization
        # so existing suppression configs continue to work.
        def code = "GLS-221"
        def category = :schema
        def severity = "error"
        def scope = :concept

        def applicable?(context)
          concept = context.concept
          return false unless concept.is_a?(V3::ManagedConcept)

          context.relations&.any? || external?(concept)
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          relations = context.relations
          issues = []

          return issues unless concept.is_a?(V3::ManagedConcept)

          relations.each_with_index do |rel, idx|
            check_cardinality(rel, idx, fname, issues)
            check_criterion_present(rel, idx, fname, issues)
            check_member_dimensions(rel, idx, fname, issues)
          end

          check_duplicate_decomposition(relations, fname, issues)
          check_external_concept(concept, fname, issues)

          issues
        end

        private

        def external?(concept)
          concept.status == "external"
        end

        def check_cardinality(rel, idx, fname, issues)
          return if rel.members.length >= 2

          issues << issue(
            "relation #{idx + 1} has fewer than 2 members " \
            "(ISO 704 requires two or more); a single binary has_part edge " \
            "should be used instead",
            location: fname,
          )
        end

        def check_criterion_present(rel, idx, fname, issues)
          return if rel.criterion && !rel.criterion.empty?

          issues << issue(
            "relation #{idx + 1} has no criterion; cannot verify " \
            "distinctness from sibling relations sharing the comprehensive " \
            "(ISO 12620 coordinate-concept coherence)",
            severity: "warning",
            location: fname,
            suggestion: "Add a criterion: { eng: '...' } field",
          )
        end

        # Warns once per member when presence or count deviates from
        # the model defaults. The warning is intentionally generic —
        # it fires for required+multiple (non-default count) just as
        # for optional+exactly_one (non-default presence). Both are
        # legal; the warning encourages an explicit, reviewed choice
        # rather than an accidental non-default.
        def check_member_dimensions(rel, idx, fname, issues)
          rel.members.each_with_index do |member, mi|
            non_default = []
            non_default << "presence='#{member.presence}'" if member.presence != DEFAULT_PRESENCE
            non_default << "count='#{member.count}'" if member.count != DEFAULT_COUNT
            next if non_default.empty?

            issues << issue(
              "relation #{idx + 1}.members[#{mi}] uses " \
              "non-default #{non_default.join(' ')} " \
              "(defaults: presence=#{DEFAULT_PRESENCE}, count=#{DEFAULT_COUNT}) " \
              "— confirm the dimensions are intentional",
              severity: "warning",
              location: fname,
              suggestion: "Non-default dimensions are valid; this warning " \
                          "exists to catch accidental drift from the model defaults.",
            )
          end
        end

        def check_duplicate_decomposition(relations, fname, issues)
          grouped = {}
          relations.each_with_index do |rel, idx|
            next unless rel.criterion && !rel.criterion.empty?

            key = criterion_key(rel)
            (grouped[key] ||= []) << idx
          end

          grouped.each do |key, idxs|
            next if idxs.length == 1

            issues << issue(
              "duplicate relation for comprehensive " \
              "#{key.first.inspect} with criterion #{key.last.inspect} " \
              "(relations ##{idxs.map { |i| i + 1 }.join(', ')}); " \
              "two relations sharing comprehensive AND criterion are the " \
              "same decomposition",
              location: fname,
            )
          end
        end

        def criterion_key(rel)
          comp = rel.comprehensive
          comp_id = comp.is_a?(ConceptRef) ? [comp.source, comp.id] : nil
          [comp_id, rel.criterion]
        end

        def check_external_concept(concept, fname, issues)
          return unless external?(concept)

          has_designation = concept.localizations.any? do |_, lc|
            lc.is_a?(LocalizedConcept) && lc.terms&.any?
          end

          return if has_designation

          issues << issue(
            "ExternalConcept (status: external) must have at least one " \
            "designation — even external concepts have a name",
            location: fname,
          )
        end
      end
    end
  end
end
