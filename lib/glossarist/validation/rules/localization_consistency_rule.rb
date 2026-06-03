# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      # Verifies that every entry in localized_concepts map points to a loaded
      # localization, and that every loaded localization has a corresponding
      # entry in the map.
      class LocalizationConsistencyRule < Base
        def code = "GLS-017"
        def category = :integrity
        def severity = "error"
        def scope = :concept

        def applicable?(context)
          context.concept.localizations&.any? ||
            context.concept.data&.localized_concepts&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          lc_map = concept.data&.localized_concepts || {}
          loaded_langs = concept.localizations&.filter_map(&:language_code) || []

          # Map has entry but no loaded localization
          lc_map.each_key do |lang|
            next if loaded_langs.include?(lang)

            issues << issue(
              "localized_concepts map has '#{lang}' but no localization loaded",
              location: fname,
              suggestion: "Add a localization for '#{lang}' or remove it from the map",
            )
          end

          # Loaded localization not in map
          loaded_langs.each do |lang|
            next if lc_map.key?(lang)

            issues << issue(
              "localization '#{lang}' is loaded but not in localized_concepts map",
              location: fname,
              suggestion: "Add '#{lang}' to the localized_concepts map",
            )
          end

          # UUID mismatch between map and loaded localization
          concept.localizations.each do |l10n|
            lang = l10n.language_code
            next unless lang

            expected_uuid = lc_map[lang]
            actual_uuid = l10n.uuid
            next unless expected_uuid && actual_uuid
            next if expected_uuid == actual_uuid

            issues << issue(
              "UUID mismatch for '#{lang}': map says '#{expected_uuid}', localization is '#{actual_uuid}'",
              location: fname,
              suggestion: "Ensure the UUID in the map matches the localization file",
            )
          end

          issues
        end
      end
    end
  end
end
