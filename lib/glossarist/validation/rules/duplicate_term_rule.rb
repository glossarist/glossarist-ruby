# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class DuplicateTermRule < Base
        def code = "GLS-302"
        def category = :quality
        def severity = "warning"
        def scope = :collection

        def applicable?(context)
          context.concepts.any?
        end

        def check(context)
          term_index = build_term_index(context.concepts)
          issues = []

          term_index.each do |(lang, term), ids|
            next if ids.size <= 1

            issues << issue(
              "Duplicate preferred term '#{term}' in #{lang}: " \
              "concepts #{ids.join(', ')}",
              code: code, severity: severity,
              location: lang,
              suggestion: "Differentiate the terms or consolidate the concepts",
            )
          end

          issues
        end

        private

        def build_term_index(concepts)
          index = Hash.new { |h, k| h[k] = [] }

          concepts.each do |concept|
            id = concept.data&.id&.to_s
            next unless id

            concept.localizations.each do |l10n|
              lang = l10n.language_code
              next unless lang

              (l10n.data&.terms || []).each do |term|
                next unless term.normative_status == "preferred"
                next unless term.designation

                index[[lang, term.designation.downcase]] << id
              end
            end
          end

          index
        end
      end
    end
  end
end

