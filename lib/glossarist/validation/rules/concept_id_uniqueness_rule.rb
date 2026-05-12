# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class ConceptIdUniquenessRule < Base
        def code = "GLS-001-uniq"
        def category = :structure
        def severity = "error"
        def scope = :collection

        def applicable?(context)
          context.concepts.any?
        end

        def check(context)
          issues = []
          seen_ids = {}

          context.concepts.each_with_index do |concept, idx|
            id = concept.data&.id&.to_s
            fname = id ? "concept-#{id}.yaml" : "concept-#{idx}.yaml"

            next unless id

            if seen_ids[id]
              issues << issue(
                "#{fname}: duplicate id '#{id}' (first seen in #{seen_ids[id]})",
                code: code, severity: "error",
              )
            else
              seen_ids[id] = fname
            end
          end

          issues
        end
      end
    end
  end
end

