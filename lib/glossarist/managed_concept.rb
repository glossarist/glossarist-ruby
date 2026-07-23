# frozen_string_literal: true

module Glossarist
  class ManagedConcept < Lutaml::Model::Serializable
    include Glossarist::Utilities::CommonFunctions

    attribute :data, ManagedConceptData, default: -> { ManagedConceptData.new }

    attribute :related, RelatedConcept, collection: true
    attribute :dates, ConceptDate, collection: true
    attribute :sources, ConceptSource, collection: true
    attribute :date_accepted, ConceptDate
    attribute :status, :string,
              values: Glossarist::GlossaryDefinition::CONCEPT_STATUSES

    attribute :uuid, :string

    attribute :version, :string
    attribute :schema_version, :string

    # identifier and id are aliases for uuid — the concept's canonical
    # identity. There is one source of truth: uuid, serialized to the
    # YAML "id" key. Having separate identifier/uuid attributes that both
    # map to the same key caused dual-mapping fragility.
    def identifier
      uuid
    end

    def identifier=(value)
      self.uuid = value
    end

    alias :id :identifier
    alias :id= :identifier=

    key_value do
      map :data, to: :data
      map :related, to: :related
      map :dates, to: :dates
      map :sources, to: :sources
      map %i[date_accepted dateAccepted],
          with: { from: :date_accepted_from_yaml, to: :date_accepted_to_yaml }
      map :status, to: :status

      map %i[id uuid], to: :uuid,
                       with: { from: :uuid_from_yaml, to: :uuid_to_yaml }
      map :schema_version, to: :schema_version
    end

    def localizations
      data.localizations
    end

    def localization(lang)
      localizations[lang]
    end
    alias :l10n :localization

    def date_accepted_from_yaml(model, value)
      model.date_accepted = ConceptDate.of_yaml(
        { "date" => value, "type" => "accepted" },
      )
    end

    def date_accepted_to_yaml(model, doc)
      return unless model.date_accepted

      doc["date_accepted"] = model.date_accepted.to_yaml_date
    end

    def uuid_to_yaml(model, doc)
      doc["id"] = model.uuid if model.uuid
    end

    def uuid_from_yaml(model, value)
      model.uuid = value if value
    end

    def uuid
      @uuid ||= Glossarist::Utilities::UUID.uuid_v5(
        Glossarist::Utilities::UUID::OID_NAMESPACE,
        to_yaml(except: %i[uuid schema_version]),
      )
    end

    def localized_concepts=(localized_concepts_collection) # rubocop:disable Metrics/AbcSize
      return unless localized_concepts_collection

      if localized_concepts_collection.is_a?(Hash)
        data.localized_concepts = stringify_keys(localized_concepts_collection)
      else
        localized_concepts_collection.each do |localized_concept_hash|
          lang = localized_concept_hash.dig("data", "language_code").to_s

          localized_concept = add_localization(
            Config.class_for(:localized_concept).of_yaml(localized_concept_hash),
          )

          data.localized_concepts[lang] = localization(lang).uuid

          localized_concept
        end
      end
    end

    def localized_concepts
      data.localized_concepts
    end

    # Adds concept localization.
    # @param localized_concept [LocalizedConcept]
    def add_localization(localized_concept)
      lang = localized_concept.language_code
      data.localized_concepts ||= {}
      data.localized_concepts[lang] =
        data.localized_concepts[lang] || localized_concept.uuid
      localized_concept.uuid = data.localized_concepts[lang]
      localizations.store(lang, localized_concept)
    end
    alias :add_l10n :add_localization

    def to_jsonld
      require "glossarist/transforms/concept_to_gloss_transform"
      Transforms::ConceptToGlossTransform.transform(self).to_jsonld
    end

    def to_turtle
      require "glossarist/transforms/concept_to_gloss_transform"
      Transforms::ConceptToGlossTransform.transform(self).to_turtle
    end

    def default_designation
      localized = localization("eng") || localizations.values.first
      terms = localized&.preferred_terms&.first || localized&.terms&.first
      terms&.designation
    end

    def default_definition
      localized = localization("eng") || localizations.values.first
      localized&.data&.definition&.first&.content
    end

    def default_lang
      localization("eng") || localizations.values.first
    end

    def all_sources
      list = Array(sources)
      list.concat(Array(data&.sources))
      localizations.each_value { |l10n| list.concat(l10n.all_sources) }
      list
    end

    def find_source_by_id(id)
      return nil if id.nil? || id.to_s.strip.empty?

      all_sources.find { |source| source.id == id }
    end

    def schema_version
      @schema_version
    end

    def assign_uuid(new_uuid)
      @uuid = new_uuid
    end

    def self.detect_schema_version(concept) # rubocop:disable Metrics/PerceivedComplexity
      raw = concept.schema_version
      if raw && !%w[legacy nil].include?(raw.to_s)
        return raw.to_s
      end

      return "3" if concept.related&.any?
      return "3" if concept.sources&.any?
      return "3" if concept.data&.domains&.any?
      return "3" if concept.is_a?(V3::ManagedConcept) &&
                     concept.partitive_relations&.any?
      return "3" if localization_has_references?(concept)

      "2"
    end

    def self.localization_has_references?(concept)
      concept.localizations&.any? do |l10n|
        l10n.is_a?(LocalizedConcept) && l10n.data&.references&.any?
      end
    end

    Glossarist::GlossaryDefinition::RELATED_CONCEPT_TYPES.each do |type|
      # List of related concepts of the specified type.
      # @return [Array<RelatedConcept>]
      define_method("#{type}_concepts") do
        related&.select { |concept| concept.type == type.to_s } || []
      end
    end
  end
end
