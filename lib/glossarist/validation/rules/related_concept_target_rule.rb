# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      # Verifies that related concept refs point to concepts that exist
      # in the dataset (for local refs) or have valid source/URN (for external).
      class RelatedConceptTargetRule < Base
        URN_RE = %r{\Aurn:[a-z0-9][a-z0-9-]{0,31}:[a-z0-9()+,\-.:=@;$_!*'%/?#]+\z}i.freeze

        def code = "GLS-110"
        def category = :references
        def severity = "warning"
        def scope = :concept

        def applicable?(context)
          context.concept.related&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          (concept.related || []).each_with_index do |rel, idx|
            ref = rel.ref
            next unless ref

            id = ref.id
            source = ref.source

            if id && local_ref?(source)
              # Local ref — concept_id must exist in dataset
              unless context.concept_ids.include?(id)
                issues << issue(
                  "related concept #{idx + 1} references '#{id}' which is not in the dataset",
                  location: fname,
                  suggestion: "Add concept '#{id}' to the dataset or fix the reference",
                )
              end
            elsif source && !id
              # Source-only ref — should be a valid URN or known format
              if source.start_with?("urn:") && !URN_RE.match?(source)
                issues << issue(
                  "related concept #{idx + 1} has invalid URN '#{source}'",
                  location: fname,
                  suggestion: "Fix the URN format (e.g. urn:iso:std:iso:ts:14812)",
                )
              end
            end
          end

          issues
        end

        private

        def local_ref?(source)
          source.nil? || source.strip.empty?
        end
      end
    end
  end
end
