# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      # Validates that domain references point to concepts that exist in the
      # dataset (for local refs with concept_id) or have a valid URN.
      class DomainTargetRule < Base
        URN_RE = %r{\Aurn:[a-z0-9][a-z0-9-]{0,31}:[a-z0-9()+,\-.:=@;$_!*'%/?#]+\z}i.freeze

        def code = "GLS-111"
        def category = :references
        def severity = "warning"
        def scope = :concept

        def applicable?(context)
          context.concept.data&.domains&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          (concept.data.domains || []).each_with_index do |domain, idx|
            if domain.concept_id && local_domain?(domain)
              unless context.concept_ids.include?(domain.concept_id)
                issues << issue(
                  "domain #{idx + 1} references '#{domain.concept_id}' not in dataset",
                  location: fname,
                  suggestion: "Add concept '#{domain.concept_id}' or fix the domain ref",
                )
              end
            elsif domain.urn
              if domain.urn.start_with?("urn:") && !URN_RE.match?(domain.urn)
                issues << issue(
                  "domain #{idx + 1} has invalid URN '#{domain.urn}'",
                  location: fname,
                  suggestion: "Fix the URN format",
                )
              end
            end
          end

          issues
        end

        private

        def local_domain?(domain)
          domain.source.nil? || domain.source.strip.empty?
        end
      end
    end
  end
end
