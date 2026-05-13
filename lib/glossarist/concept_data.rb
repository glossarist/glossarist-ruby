module Glossarist
  class ConceptData < Lutaml::Model::Serializable
    include Glossarist::Utilities::CommonFunctions

    attribute :dates, ConceptDate, collection: true
    attribute :definition, DetailedDefinition,
              collection: Collections::DetailedDefinitionCollection,
              initialize_empty: true
    attribute :examples, DetailedDefinition,
              collection: Collections::DetailedDefinitionCollection,
              initialize_empty: true
    attribute :id, :string
    attribute :lineage_source_similarity, :integer
    attribute :notes, DetailedDefinition,
              collection: Collections::DetailedDefinitionCollection,
              initialize_empty: true
    attribute :release, :string
    attribute :sources, ConceptSource,
              collection: Collections::ConceptSourceCollection,
              initialize_empty: true
    attribute :terms, Designation::Base, collection: true
    attribute :related, RelatedConcept, collection: true
    attribute :references, ConceptReference, collection: true
    attribute :domain, :string
    attribute :review_date, :date_time
    attribute :review_decision_date, :date_time
    attribute :review_decision_event, :string

    # Concept Methods
    # Language code should be exactly 3 char long.
    # TODO: use min_length, max_length once added in lutaml-model
    attribute :language_code, :string, pattern: /^.{3}$/
    attribute :script, :string
    attribute :system, :string
    attribute :entry_status, :string

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
      map %i[review_decision_date reviewDecisionDate], to: :review_decision_date
      map %i[review_decision_event reviewDecisionEvent],
          to: :review_decision_event
    end

    def terms_from_yaml(model, value)
      model.terms = value.map { |v| Designation::Base.of_yaml(v) }
    end

    def terms_to_yaml(model, doc)
      doc["terms"] = model.terms&.map(&:to_yaml_hash)
    end

    def date_accepted
      return nil unless dates

      dates.find(&:accepted?)
    end

    def authoritative_source
      return [] unless sources

      sources.select(&:authoritative?)
    end
  end
end
