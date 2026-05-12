# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class L10nUuidIntegrityRule < Base
        def code = "GLS-018"
        def category = :integrity
        def severity = "error"
        def scope = :concept

        def applicable?(context)
          context.collection_context.localization_index.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          lc_map = concept.data.localized_concepts || {}
          lc_index = context.collection_context.localization_index
          issues = []

          lc_map.each do |lang, uuid|
            next if lc_index.key?(uuid)

            issues << issue(
              "localized_concepts '#{lang}' => '#{uuid}' has no matching file",
              code: code, severity: severity,
              location: fname,
              suggestion: "Add the missing localization file or remove the UUID",
            )
          end

          issues
        end
      end
    end
  end
end

