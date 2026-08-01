# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      # Validates that external concepts referenced by hyperedges have
      # a `provided_by` edge for resolution. Mirrors concept-model's
      # `check-external-as-comprehensive` validator, exposed as a
      # consumer-side Validation::Rule so it runs in the standard
      # validation pipeline.
      #
      # Per concept-model docs/design/external-concepts.md: an external
      # concept (status: external) is referenced from this dataset but
      # defined elsewhere. Without a `provided_by` edge, the reference
      # dangles — there is no resolvable target. ISO 704 models this
      # case as a parenthetical term in the diagram; the data model
      # requires the resolution edge to exist.
      #
      # Scope: concept (rule runs once per concept). The concept's
      # relations are inspected via `context.relations`; each
      # relation's comprehensive + members are checked.
      #
      # Requires a `concept_resolver` on the context. Without one,
      # the rule is a no-op (cannot detect externals without
      # resolution).
      class ExternalConceptRule < Base
        def code = "GLS-222"
        def category = :schema
        def severity = "warning"
        def scope = :concept

        def applicable?(context)
          return false unless context.concept.is_a?(V3::ManagedConcept)
          return false unless context.concept_resolver
          return false if context.relations.empty?

          true
        end

        def check(context)
          resolver = context.concept_resolver
          issues = []

          context.relations.each_with_index do |rel, idx|
            check_comprehensive(rel, idx, context.file_name, resolver, issues)
            check_members(rel, idx, context.file_name, resolver, issues)
          end

          issues
        end

        private

        def check_comprehensive(rel, idx, fname, resolver, issues)
          return unless rel.external_comprehensive?(resolver)

          comp_id = Glossarist::ConceptRef.qualified_id(rel.comprehensive)
          issues << issue(
            "relation #{idx + 1} comprehensive #{comp_id.inspect} is " \
            "external (status: external) — confirm a `provided_by` edge " \
            "exists on the external concept so the decomposition resolves",
            location: fname,
            severity: "info",
            suggestion: "Add `provided_by` to #{comp_id}'s related list.",
          )
        end

        def check_members(rel, idx, fname, resolver, issues)
          rel.external_members(resolver).each_with_index do |member, mi|
            member_id = Glossarist::ConceptRef.qualified_id(member.ref)
            has_resolution = resolver.call(member.ref)&.related&.any? do |r|
              r.respond_to?(:type) && r.type == "provided_by"
            end

            next if has_resolution

            issues << issue(
              "relation #{idx + 1}.members[#{mi}] #{member_id.inspect} is " \
              "external (status: external) without a `provided_by` edge — " \
              "the decomposition dangles; no resolvable target",
              location: fname,
              severity: "warning",
              suggestion: "Add `provided_by` to #{member_id}'s related " \
                          "list, or define the concept in this dataset.",
            )
          end
        end
      end
    end
  end
end
