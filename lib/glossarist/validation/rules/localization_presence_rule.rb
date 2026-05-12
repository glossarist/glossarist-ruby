# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class LocalizationPresenceRule < Base
        def code = "GLS-002"
        def category = :structure
        def scope = :concept

        def check(context)
          concept = context.concept
          fname = context.file_name
          l10ns = concept.localizations&.values || []

          return [] if l10ns.any?

          [issue("#{fname}: no localizations found",
                 code: code, severity: "error")]
        end
      end
    end
  end
end

