# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class OrphanedL10nFilesRule < Base
        def code = "GLS-019"
        def category = :integrity
        def severity = "warning"
        def scope = :collection

        def applicable?(context)
          context.localization_index.any?
        end

        def check(context)
          lc_index = context.localization_index
          referenced = context.referenced_l10n_uuids
          issues = []

          lc_index.each do |uuid, path|
            next if referenced.include?(uuid)

            issues << issue(
              "Orphaned localization file: #{File.basename(path)} " \
              "(not referenced by any concept)",
              code: code, severity: severity,
              location: File.basename(path),
              suggestion: "Delete the file or add a reference from a managed concept",
            )
          end

          issues
        end
      end
    end
  end
end

