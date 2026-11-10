# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      # glossarist#6: a concept with localizations must carry one in the
      # dataset's default language (Config.default_language, "eng" unless
      # customized). Concepts with no localizations at all are not this
      # rule's concern.
      class DefaultLanguageRule < Base
        def code = "GLS-311"
        def category = :content
        def severity = "error"
        def scope = :concept

        def check(context)
          concept = context.concept
          l10ns = concept.localizations || {}
          return [] if l10ns.empty?

          default = Config.default_language
          return [] if l10ns.keys.include?(default)

          [issue(
            "#{context.file_name}: no localization in the default " \
            "language '#{default}' (has: #{l10ns.keys.join(', ')})",
            code: code, severity: severity,
            location: context.file_name,
            suggestion: "add a '#{default}' localization or set " \
                        "default_language in glossarist.yaml"
          )]
        end
      end
    end
  end
end
