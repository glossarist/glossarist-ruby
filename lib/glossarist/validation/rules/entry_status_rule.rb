# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class EntryStatusRule < Base
        def code = "GLS-003"
        def category = :schema
        def severity = "error"
        def scope = :concept

        VALID_STATUSES = %w[valid superseded withdrawn draft].freeze

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          (concept.localizations&.values || []).each do |l10n|
            lang = l10n.language_code || "unknown"
            status = l10n.data&.entry_status
            next unless status
            next if VALID_STATUSES.include?(status)

            issues << issue(
              "#{fname}/#{lang}: invalid entry_status '#{status}' " \
              "(expected one of: #{VALID_STATUSES.join(', ')})",
              code: code, severity: "error",
              location: "#{fname}/#{lang}",
            )
          end

          issues
        end
      end
    end
  end
end

