# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class ConceptMentionRule < Base
        def code = "GLS-100"
        def category = :references
        def severity = "warning"
        def scope = :concept

        def applicable?(context)
          context.concept.localizations&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          extractor = ReferenceExtractor.new
          issues = []

          refs = extractor.extract_from_managed_concept(concept)
            .select { |r| r.is_a?(ConceptReference) && r.local? }

          refs.each do |ref|
            next if ref.ref_type == "designation"
            next if context.concept_ids.include?(ref.concept_id)

            issues << issue(
              "unresolved intra-set reference: #{ref.term} -> #{ref.concept_id}",
              code: "GLS-100", severity: severity,
              location: fname,
              suggestion: "add concept '#{ref.concept_id}' to the dataset " \
                          "or verify the reference",
            )
          end

          issues
        end
      end
    end
  end
end

