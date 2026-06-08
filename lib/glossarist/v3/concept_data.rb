# frozen_string_literal: true

module Glossarist
  module V3
    class ConceptData < Glossarist::ConceptData
      attribute :sources, V3::ConceptSource,
                collection: Collections::ConceptSourceCollection,
                initialize_empty: true
      attribute :definition, V3::DetailedDefinition,
                collection: Collections::DetailedDefinitionCollection,
                initialize_empty: true
      attribute :examples, V3::DetailedDefinition,
                collection: Collections::DetailedDefinitionCollection,
                initialize_empty: true
      attribute :notes, V3::DetailedDefinition,
                collection: Collections::DetailedDefinitionCollection,
                initialize_empty: true
      attribute :annotations, V3::DetailedDefinition,
                collection: Collections::DetailedDefinitionCollection,
                initialize_empty: true
      attribute :related, V3::RelatedConcept, collection: true

      def self.detailed_definition_fields
        super + %i[annotations]
      end

      key_value do
        map :dates, to: :dates
        map :definition, to: :definition
        map :examples, to: :examples
        map :id, to: :id
        map %i[lineage_source_similarity lineageSourceSimilarity],
            to: :lineage_source_similarity
        map :notes, to: :notes
        map :annotations, to: :annotations
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
