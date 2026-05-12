# frozen_string_literal: true

module Glossarist
  class ConceptEnricher
    def inject_references(concepts) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      extractor = ReferenceExtractor.new

      concepts.each do |mc|
        mc.localizations.each do |l10n|
          refs = extractor.extract_from_localized_concept(l10n)
            .grep(ConceptReference)
          next if refs.empty?

          existing = l10n.data.references || []
          seen_keys = existing.to_set { |r| [r.source, r.concept_id] }

          refs.each do |ref|
            key = [ref.source, ref.concept_id]
            next if seen_keys.include?(key)

            seen_keys.add(key)
            existing << ref
          end
          l10n.data.references = existing
        end
      end
    end

    def apply_uri_template(concepts, template)
      concepts.each do |mc|
        mc.data.uri = template.sub("{id}", mc.data.id.to_s)
      end
    end
  end
end
