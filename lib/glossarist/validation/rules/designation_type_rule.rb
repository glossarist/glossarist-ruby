# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class DesignationTypeRule < Base
        def code = "GLS-207"
        def category = :schema
        def severity = "error"
        def scope = :concept

        VALID_TYPES = Designation::SERIALIZED_TYPES.values.grep(String).uniq.freeze

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
              type = designation_type(term)
              next unless type

              unless VALID_TYPES.include?(type)
                issues << issue(
                  "#{lang}: term #{idx + 1} has unknown designation type '#{type}'",
                  location: fname,
                  suggestion: "Use one of: #{VALID_TYPES.join(', ')}",
                )
              end
            end
          end

          issues
        end

        private

        def designation_type(term)
          if term.is_a?(Hash)
            term["type"]
          elsif term.respond_to?(:type)
            term.type
          end
        end
      end
    end
  end
end
