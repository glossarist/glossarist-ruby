# frozen_string_literal: true

module Glossarist
  module V3
    class ManagedConceptData < Glossarist::ManagedConceptData
      attribute :sources, V3::ConceptSource, collection: true
      attribute :localizations, V3::LocalizedConcept,
                collection: Collections::LocalizationCollection,
                initialize_empty: true

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
      end

      def localizations_from_yaml(model, value)
        value.each do |localized_concept_hash|
          localized_concept = V3::LocalizedConcept.of_yaml(localized_concept_hash)
          model.localizations.store(localized_concept.language_code,
                                    localized_concept)
        end
      end

      def localizations_to_yaml(model, doc); end
    end
  end
end
