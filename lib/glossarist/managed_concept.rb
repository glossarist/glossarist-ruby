require_relative "localized_concept"

module Glossarist
  class ManagedConcept < Lutaml::Model::Serializable
    include Glossarist::Utilities::CommonFunctions

    attribute :data, ManagedConceptData, default: -> { ManagedConceptData.new }

    attribute :related, RelatedConcept, collection: true
    attribute :dates, ConceptDate, collection: true
    attribute :sources, ConceptSource
    attribute :date_accepted, ConceptDate
    # TODO: convert to LocalizedConceptCollection when custom
    #       collections are implemented in lutaml-model
    attribute :status, :string,
              values: Glossarist::GlossaryDefinition::CONCEPT_STATUSES

    attribute :identifier, :string
    alias :id :identifier
    alias :id= :identifier=

    attribute :uuid, :string

    yaml do
      map :data, to: :data
      map :id, with: { to: :identifier_to_yaml, from: :identifier_from_yaml }
      map :identifier,
          with: { to: :identifier_to_yaml, from: :identifier_from_yaml }
      map :related, to: :related
      map :dates, to: :dates
      map %i[date_accepted dateAccepted], with: { from: :date_accepted_from_yaml, to: :date_accepted_to_yaml }
      map :status, to: :status

      map :uuid, to: :uuid, with: { from: :uuid_from_yaml, to: :uuid_to_yaml }
    end

    def localized_concepts
      data.localized_concepts
    end

    def localized_concepts=(val)
      data.localized_concepts = val
    end

    def localizations
      data.localizations
    end

    def localization(lang)
      localizations[lang]
    end
    alias :l10n :localization

    def date_accepted_from_yaml(model, value)
      model.dates ||= []
      model.dates << ConceptDate.of_yaml({ "date" => value,
                                           "type" => "accepted" })
    end

    def date_accepted_to_yaml(model, doc)
      doc["date_accepted"] = model.date_accepted.date if model.date_accepted
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
        to_yaml(except: [:uuid]),
      )
    end

    def identifier_to_yaml(model, doc)
      value = model.identifier || model.id
      doc["id"] = value if value && !doc["id"]
    end

    def identifier_from_yaml(model, value)
      model.identifier = value || model.identifier
    end

    def localized_concepts=(localized_concepts_collection)
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
      localizations.store(lang, localized_concept)
    end
    alias :add_l10n :add_localization

    # Returns concept localization.
    # @param lang [String] language code
    # @return [LocalizedConcept]
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

    Glossarist::GlossaryDefinition::RELATED_CONCEPT_TYPES.each do |type|
      # List of related concepts of the specified type.
      # @return [Array<RelatedConcept>]
      define_method("#{type}_concepts") do
        related&.select { |concept| concept.type == type.to_s } || []
      end
    end
  end
end
