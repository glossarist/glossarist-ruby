# frozen_string_literal: true

module Glossarist
  module V2
    class ConceptData < Glossarist::ConceptData
      attribute :sources, V2::ConceptSource,
                collection: Collections::ConceptSourceCollection,
                initialize_empty: true
      attribute :definition, V2::DetailedDefinition,
                collection: Collections::DetailedDefinitionCollection,
                initialize_empty: true
      attribute :examples, V2::DetailedDefinition,
                collection: Collections::DetailedDefinitionCollection,
                initialize_empty: true
      attribute :notes, V2::DetailedDefinition,
                collection: Collections::DetailedDefinitionCollection,
                initialize_empty: true
      attribute :related, V2::RelatedConcept, collection: true

      key_value do
        map :dates, to: :dates
        map :definition, to: :definition, value_map: { to: { empty: :empty } }
        map :examples, to: :examples, value_map: { to: { empty: :empty } }
        map :id, to: :id
        map %i[lineage_source_similarity lineageSourceSimilarity],
            to: :lineage_source_similarity
        map :notes, to: :notes, value_map: { to: { empty: :empty } }
        map :release, to: :release
        map :sources, to: :sources
        map :terms, to: :terms,
                    with: { from: :terms_from_yaml, to: :terms_to_yaml }
        map :related, to: :related
        map :references, to: :references
        map :domain, to: :domain
        map %i[language_code languageCode], to: :language_code
        map :script, to: :script
        map :system, to: :system
        map %i[entry_status entryStatus], to: :entry_status
        map %i[review_date reviewDate], to: :review_date
        map %i[review_decision_date reviewDecisionDate],
            to: :review_decision_date
        map %i[review_decision_event reviewDecisionEvent],
            to: :review_decision_event
      end
    end
  end
end
