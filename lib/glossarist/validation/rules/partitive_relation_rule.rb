# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      # Validates semantic invariants of PartitiveRelation entries
      # that the model constructor does NOT enforce. Specifically:
      #
      #   - error when a relation has fewer than 2 partitives
      #     (ISO 704: "two or more"; single binary should use
      #     has_part edge instead)
      #   - error when two relations share the same comprehensive
      #     AND the same non-nil criterion (duplicate decomposition;
      #     ISO 12620 coordinate-concept coherence)
      #   - warning when a relation has no criterion (cannot
      #     distinguish from siblings sharing the comprehensive)
      #   - warning when multiplicity is not the default compulsory
      #     (encourages explicit statement of optional/multiple)
      #   - error when ExternalConcept (status: external) lacks
      #     at least one designation
      #
      # The model constructor already rejects empty comprehensive,
      # empty partitives list, self-loops, invalid enum values.
      class PartitiveRelationRule < Base
        def code = "GLS-221"
        def category = :schema
        def severity = "error"
        def scope = :concept

        def applicable?(context)
          concept = context.concept
          return false unless concept.is_a?(V3::ManagedConcept)

          concept.partitive_relations&.any? || external?(concept)
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          return issues unless concept.is_a?(V3::ManagedConcept)

          relations = Array(concept.partitive_relations)

          relations.each_with_index do |rel, idx|
            check_cardinality(rel, idx, fname, issues)
            check_criterion_present(rel, idx, fname, issues)
            check_member_multiplicity(rel, idx, fname, issues)
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
          return if rel.partitives.length >= 2

          issues << issue(
            "partitive_relation #{idx + 1} has fewer than 2 partitives " \
            "(ISO 704 requires two or more); a single binary has_part edge " \
            "should be used instead",
            location: fname,
          )
        end

        def check_criterion_present(rel, idx, fname, issues)
          return if rel.criterion && !rel.criterion.empty?

          issues << issue(
            "partitive_relation #{idx + 1} has no criterion; cannot verify " \
            "distinctness from sibling relations sharing the comprehensive " \
            "(ISO 12620 coordinate-concept coherence)",
            severity: "warning",
            location: fname,
            suggestion: "Add a criterion: { eng: '...' } field",
          )
        end

        def check_member_multiplicity(rel, idx, fname, issues)
          rel.partitives.each_with_index do |member, mi|
            unless member.compulsory?
              issues << issue(
                "partitive_relation #{idx + 1}.partitives[#{mi}] has " \
                "non-default multiplicity '#{member.multiplicity}'; " \
                "ISO 704 diagram uses dashed/multiple-line notation for " \
                "this — confirm the optionality is intentional",
                severity: "warning",
                location: fname,
              )
            end

            next unless member.delimiting?

            issues << issue(
              "partitive_relation #{idx + 1}.partitives[#{mi}] is marked " \
              "delimiting (ISO 704 bold 3x-width line); behaves like a " \
              "delimiting characteristic distinguishing the comprehensive " \
              "from coordinate concepts",
              severity: "info",
              location: fname,
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
              "duplicate PartitiveRelation for comprehensive " \
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
