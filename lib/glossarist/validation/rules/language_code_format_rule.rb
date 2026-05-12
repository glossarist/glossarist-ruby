# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class LanguageCodeFormatRule < Base
        def code = "GLS-206"
        def category = :schema
        def severity = "error"
        def scope = :concept

        def applicable?(context)
          context.concept.localizations&.any?
        end

        def check(context)
          concept = context.concept
          fname = context.file_name
          issues = []

          concept.localizations.each do |l10n|
            lang = l10n.language_code
            next if lang.nil?

            unless lang.to_s.match?(/\A[a-z]{3}\z/)
              issues << issue(
                "language_code '#{lang}' is not a valid ISO 639-3 code (expected 3 lowercase letters)",
                location: fname,
                suggestion: "Use a 3-letter ISO 639-3 code (e.g. eng, fra, deu)",
              )
            end
          end

          issues
        end
      end
    end
  end
end
