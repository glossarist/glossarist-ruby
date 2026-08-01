# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      # Validates that extensional definitions do not contain open-ended
      # wording, per ISO 704:2022 §6.4.5.1. An extensional definition
      # must be an EXHAUSTIVE enumeration — open-ended wordings like
      # `...`, `etc.`, `and so on`, `and similar`, `and others`,
      # `including` violate this principle because they imply the
      # enumeration is incomplete.
      #
      # Mirrors concept-model's `check-definition-rules`
      # §6.4.5.1 open-ended-wording check, exposed as a consumer-side
      # Validation::Rule.
      #
      # Scope: concept (rule runs once per concept). Inspects every
      # DetailedDefinition with `type: extensional` across all of the
      # concept's localized definitions.
      class ExtensionalDefinitionRule < Base
        # ISO 704:2022 §6.4.5.1 — patterns that signal incomplete
        # enumeration in an extensional definition. The list is
        # intentionally conservative: only wordings that clearly
        # indicate "more exist beyond what's listed."
        OPEN_ENDED_PATTERNS = [
          /\.\.\./,                         # ellipsis
          /\betc\b\.?/i,                    # etc / etc.
          /\band\s+similar\b/i,             # and similar
          /\band\s+so\s+on\b/i,             # and so on
          /\band\s+the\s+like\b/i,          # and the like
          /\band\s+others?\b/i,             # and other / and others
          /\bsuch\s+as\b/i,                 # such as (often partial)
          /\bincluding\b/i,                 # including (often partial)
          /\be\.?g\.?\b/i,                  # e.g. / eg
        ].freeze

        def code = "GLS-223"
        def category = :schema
        def severity = "warning"
        def scope = :concept

        def applicable?(context)
          return false unless context.concept.is_a?(V3::ManagedConcept)

          concept_has_extensional_definition?(context.concept)
        end

        def check(context)
          issues = []

          each_extensional_definition(context.concept) do |l10n_lang, defn, path|
            check_definition(defn, l10n_lang, path, context.file_name, issues)
          end

          issues
        end

        private

        def concept_has_extensional_definition?(concept)
          each_extensional_definition(concept).any? { true }
        rescue StopIteration
          false
        end

        # Yields (lang, definition, path_string) for every extensional
        # definition on every localization of the concept.
        def each_extensional_definition(concept)
          return enum_for(:each_extensional_definition, concept) unless block_given?

          concept.localizations.each_value do |l10n|
            next unless l10n.respond_to?(:data)

            lang = l10n.language_code
            %i[definition examples notes].each do |field|
              value = l10n.data&.public_send(field)
              next if value.nil?

              Array(value).each_with_index do |item, idx|
                next unless item.is_a?(Glossarist::DetailedDefinition) ||
                  item.is_a?(V3::DetailedDefinition)
                next unless item.type.to_s == "extensional"

                yield lang, item, "#{field}[#{idx}]"
              end
            end
          end
        end

        def check_definition(defn, lang, path, fname, issues)
          content = extract_content(defn)
          return if content.nil? || content.empty?

          OPEN_ENDED_PATTERNS.each do |pattern|
            match = content.match(pattern)
            next unless match

            issues << issue(
              "#{path} (#{lang}) extensional definition contains " \
              "open-ended wording #{match[0].inspect}; ISO 704:2022 " \
              "§6.4.5.1 requires exhaustive enumeration in " \
              "extensional definitions",
              location: fname,
              severity: "warning",
              suggestion: "Either enumerate all instances exhaustively, " \
                          "or change the definition type to intensional.",
            )
            break # one issue per definition is enough
          end
        end

        def extract_content(definition)
          return definition.content if definition.respond_to?(:content)

          nil
        end
      end
    end
  end
end
