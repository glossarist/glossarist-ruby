# frozen_string_literal: true

module Glossarist
  module V2
    class ManagedConceptData < Glossarist::ManagedConceptData
      attribute :sources, V2::ConceptSource, collection: true
      attribute :localizations, V2::LocalizedConcept,
                collection: Collections::LocalizationCollection,
                initialize_empty: true
      attribute :related, V2::RelatedConcept, collection: true

      key_value do
        map %i[id identifier], to: :id,
                               with: { to: :id_to_yaml, from: :id_from_yaml }
        map :uri, to: :uri
        map %i[localized_concepts localizedConcepts], to: :localized_concepts
        map %i[domains groups], to: :domains,
                                with: { from: :domains_from_yaml, to: :domains_to_yaml }
        map :sources, to: :sources
        map :localizations, to: :localizations,
                            with: { from: :localizations_from_yaml, to: :localizations_to_yaml }
        map :related, to: :related,
                      with: { from: :related_from_yaml, to: :related_to_yaml }
      end

      def localizations_from_yaml(model, value)
        value.each do |localized_concept_hash|
          localized_concept = V2::LocalizedConcept.of_yaml(localized_concept_hash)
          model.localizations.store(localized_concept.language_code,
                                    localized_concept)
        end
      end

      def localizations_to_yaml(model, doc); end

      def related_from_yaml(model, value)
        return unless value.is_a?(Array)

        model.related = value.map { |r| V2::RelatedConcept.of_yaml(r) }
      end

      def related_to_yaml(model, doc)
        return unless model.related&.any?

        doc["related"] = model.related.map(&:to_hash)
      end
    end
  end
end
