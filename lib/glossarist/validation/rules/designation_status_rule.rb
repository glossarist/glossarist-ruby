# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class DesignationStatusRule < Base
        def code = "GLS-204"
        def category = :schema
        def severity = "error"
        def scope = :concept

        VALID_STATUSES = Glossarist::GlossaryDefinition::DESIGNATION_BASE_NORMATIVE_STATUSES

        def applicable?(context)
          context.concept.localizations&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          concept.localizations.each do |l10n|
            lang = l10n.language_code || "unknown"
            terms = l10n.data&.terms || []
            terms.each_with_index do |term, idx|
              next unless term.respond_to?(:normative_status)
              next if term.normative_status.nil? || term.normative_status.to_s.strip.empty?

              unless VALID_STATUSES.include?(term.normative_status.to_s)
                issues << issue(
                  "#{lang}: term #{idx + 1} has invalid normative_status '#{term.normative_status}'",
                  location: fname,
                  suggestion: "Use one of: #{VALID_STATUSES.join(', ')}",
                )
              end
            end
          end

          issues
        end
      end
    end
  end
end
