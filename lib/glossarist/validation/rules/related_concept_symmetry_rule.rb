# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class RelatedConceptSymmetryRule < Base
        def code = "GLS-112"
        def category = :references
        def severity = "warning"
        def scope = :collection

        INVERSE = {
          "supersedes" => "superseded_by",
          "superseded_by" => "supersedes",
          "narrower" => "broader",
          "broader" => "narrower",
          "deprecates" => "deprecated_by",
          "deprecated_by" => "deprecates",
        }.freeze

        DIRECTIONAL = %w[supersedes deprecates narrower].freeze

        def applicable?(context)
          context.concepts.any? { |c| c.related&.any? }
        end

        def check(context)
          index = build_relation_index(context.concepts)
          issues = []

          context.concepts.each do |concept|
            next unless concept.related&.any?

            concept_id = concept.data&.id&.to_s || "unknown"
            (concept.related || []).each do |rel|
              inverse = INVERSE[rel.type]
              next unless inverse

              target_id = resolve_target_id(rel)
              next unless target_id

              targets = index[target_id]
              next if targets && targets.any? { |r| r.type == inverse }

              issues << issue(
                "#{concept_id}: #{rel.type} #{target_id} but #{target_id} has no #{inverse} back-link",
                location: concept_id,
                suggestion: "Add a #{inverse} relation on #{target_id} pointing back to #{concept_id}",
              )
            end
          end

          issues
        end

        private

        def build_relation_index(concepts)
          index = {}
          concepts.each do |c|
            next unless c.related&.any?

            src_id = c.data&.id&.to_s
            next unless src_id

            c.related.each do |rel|
              target_id = resolve_target_id(rel)
              next unless target_id

              (index[src_id] ||= []) << rel
            end
          end
          index
        end

        def resolve_target_id(rel)
          ref = rel.ref
          return nil unless ref

          if ref.is_a?(Glossarist::Citation)
            ref.id || ref.text
          end
        end
      end
    end
  end
end
