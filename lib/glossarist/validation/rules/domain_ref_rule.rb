# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class DomainRefRule < Base
        def code = "GLS-309"
        def category = :quality
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
            has_ref = domain.concept_id || domain.urn
            unless has_ref
              issues << issue(
                "domain #{idx + 1} has neither concept_id nor urn",
                location: fname,
                suggestion: "Provide at least concept_id or urn for the domain reference",
              )
            end

            next unless domain.ref_type == "section" && domain.concept_id

            register = context.collection_context.dataset_register
            next unless register

            unless register.section_exists?(domain.concept_id)
              issues << issue(
                "domain #{idx + 1} references section '#{domain.concept_id}' " \
                "that does not exist in register.yaml",
                location: fname,
                suggestion: "Add section '#{domain.concept_id}' to " \
                            "register.yaml or fix the reference",
              )
            end
          end

          issues
        end
      end
    end
  end
end
