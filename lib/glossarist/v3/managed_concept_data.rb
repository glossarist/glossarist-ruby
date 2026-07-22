# frozen_string_literal: true

module Glossarist
  module V3
    # V3 ManagedConceptData — the data payload inside a V3::ManagedConcept.
    #
    # V3 placement rule (MECE): `related` lives ONLY on V3::ManagedConcept,
    # not on its data payload. V2 placed `related` inside data; the
    # V2→V3 migration (SchemaMigration::V2ToV3) moves it to the concept
    # level. Keeping `related` writable on V3 data would re-open the
    # trap where writing to `data.related` bypasses
    # `ManagedConcept.detect_schema_version` (which keys off
    # `concept.related`).
    #
    # The base class Glossarist::ManagedConceptData still declares
    # `related` for V1/V2 compatibility; V3 overrides that with an
    # empty attribute via `attribute :related, nil` so the slot is
    # inert and serializes nothing.
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
        map :tags, to: :tags
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

