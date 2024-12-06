require_relative "localized_concept"

module Glossarist
  module LutamlModel
    class ManagedConcept < Lutaml::Model::Serializable
      include Glossarist::Utilities::CommonFunctions

      attribute :related, RelatedConcept
      attribute :dates, ConceptDate, collection: true
      attribute :localized_concept, :hash
      attribute :groups, :string, collection: true
      attribute :sources, ConceptSource
      attribute :date_accepted, ConceptDate
      attribute :localizations, :hash, default: -> { {} }
      attribute :localized_concepts, :hash, default: -> { {} }
      attribute :data, :hash
      attribute :status, :string, values: Glossarist::GlossaryDefinition::CONCEPT_STATUSES
      attribute :identifier, :string
      attribute :id, :string
      attribute :uuid, :string

      yaml do
        map :data, with: { to: :data_to_yaml, from: :data_from_yaml }
        map :identifier, with: { to: :identifier_to_yaml, from: :identifier_from_yaml }
        map :id, with: { to: :identifier_to_yaml, from: :identifier_from_yaml }
        map :related, to: :related
        map :dates, to: :dates
        map :localized_concept, to: :localized_concept
        map :groups, to: :groups
        map :sources, with: { to: :sources_to_yaml, from: :sources_from_yaml }
        map :localizations, to: :localizations
        map :date_accepted, with: { from: :date_accepted_from_yaml, to: :date_accepted_to_yaml }
        map :localized_concepts, to: :localized_concepts
        map :status, to: :status

        map :uuid, to: :uuid, with: { from: :uuid_from_yaml, to: :uuid_to_yaml }
      end

      def initialize(attributes = {})
        attributes = symbolize_keys(attributes)
        @uuid = attributes[:uuid]

        data = attributes.delete(:data) || {}
        data["groups"] = attributes[:groups]
        data["status"] = attributes[:status]

        data = symbolize_keys(data.compact)
        data[:identifier] = data[:id] if data[:id]
        super(slice_keys(data, managed_concept_attributes))
      end

      def id
        @id || @identifier
      end

      def identifier
        @id || @identifier
      end

      def id=(val)
        @identifier = val
      end

      def identifier=(val)
        @identifier = val
      end

      def date_accepted_from_yaml(model, value)
        model.dates ||= []
        model.dates << ConceptDate.of_yaml({ "date" => value, "type" => "accepted" })
      end

      def date_accepted_to_yaml(model, doc)
        doc["date_accepted"] = model.date_accepted.date if model.date_accepted
      end

      def data_to_yaml(model, doc)
        doc["data"] = model.data_hash
      end

      def data_from_yaml(model, value)
      end

      def uuid_to_yaml(model, doc)
        doc["id"] = model.uuid
      end

      def uuid_from_yaml(model, value)
        model.uuid = value if value
      end

      def uuid
        @uuid ||= Glossarist::Utilities::UUID.uuid_v5(Glossarist::Utilities::UUID::OID_NAMESPACE, to_yaml(except: [:uuid]))
      end

      def data_hash
        {
          "identifier" => identifier || id,
          "localized_concepts" => localized_concepts.empty? ? nil : localized_concepts,
          "groups" => groups.empty? ? nil : groups,
          "sources" => sources&.map(&:to_yaml_hash),
        }.compact
      end

      def localized_concept_class
        @localized_concept_class ||= Glossarist::LutamlModel::LocalizedConcept #Config.class_for(:localized_concept)
      end

      def sources_to_yaml(model, doc)
      end

      def sources_from_yaml(model, value)
        model.sources = ConceptSource.of_yaml(value)
      end

      def identifier_to_yaml(model, doc)
        doc["data"]["identifier"] = (model.identifier || model.id) || doc["data"]["identifier"]
      end

      def identifier_from_yaml(model, value)
        model.identifier = value || model.identifier
      end

      def self.of_yaml(doc, options = {})
        data = doc["data"]
        data["identifier"] = data.delete("id") if data["id"]
        data["uuid"] = doc["uuid"] if doc["uuid"]
        data["groups"] = doc["groups"] if doc["groups"]

        super(doc["data"], options)
      end

      def related=(related)
        @related = related&.map { |r| RelatedConcept.new(r) }
      end

      def dates=(dates)
        @dates = dates&.map { |d| ConceptDate.new(d) }
      end

      def groups=(groups)
        return unless groups

        @groups = groups.is_a?(Array) ? groups : [groups]
      end

      def localized_concepts=(localized_concepts_collection)
        return unless localized_concepts_collection

        if localized_concepts_collection.is_a?(Hash)
          @localized_concepts = stringify_keys(localized_concepts_collection)
        else
          localized_concepts_collection.each do |localized_concept_hash|
            lang = localized_concept_hash["language_code"].to_s

            localized_concept = add_localization(
              localized_concept_class.of_yaml(localized_concept_hash["data"] || localized_concept_hash),
            )

            @localized_concepts[lang] = localization(lang).uuid

            localized_concept
          end
        end
      end

      attr_reader :localized_concepts

      def sources=(sources)
        @sources = sources&.map do |source|
          next source unless source.is_a?(Hash)

          ConceptSource.of_yaml(source)
        end
      end

      # Adds concept localization.
      # @param localized_concept [LocalizedConcept]
      def add_localization(localized_concept)
        lang = localized_concept.language_code
        @localized_concepts ||= {}
        @localized_concepts[lang] = @localized_concepts[lang] || localized_concept.uuid
        localizations.store(lang, localized_concept)
      end

      alias :add_l10n :add_localization

      def localizations=(localizations)
        return unless localizations

        @localizations = {}

        localizations.each do |localized_concept|
          unless localized_concept.is_a?(localized_concept_class)
            localized_concept = localized_concept_class.new(
              localized_concept["data"] || localized_concept,
            )
          end

          add_l10n(localized_concept)
        end
      end

      def date_accepted=(date)
        date_hash = {
          "type" => "accepted",
          "date" => date,
        }

        @dates ||= []
        @dates << ConceptDate.new(date_hash)
      end

      # Returns concept localization.
      # @param lang [String] language code
      # @return [LocalizedConcept]
      def localization(lang)
        localizations[lang]
      end

      alias :l10n :localization

      def default_designation
        localized = localization("eng") || localizations.values.first
        terms = localized&.preferred_terms&.first || localized&.terms&.first
        terms&.designation
      end

      def default_definition
        localized = localization("eng") || localizations.values.first
        localized&.definition&.first&.content
      end

      def default_lang
        localization("eng") || localizations.values.first
      end

      def managed_concept_attributes
        %i[
          data
          id
          identifier
          uuid
          related
          status
          dates
          date_accepted
          dateAccepted
          localized_concepts
          localizedConcepts
          localizations
          groups
          sources
        ].compact
      end

      Glossarist::GlossaryDefinition::RELATED_CONCEPT_TYPES.each do |type|
        # List of related concepts of the specified type.
        # @return [Array<RelatedConcept>]
        define_method("#{type}_concepts") do
          related&.select { |concept| concept.type == type.to_s } || []
        end
      end

      def localizations_hash
        localizations.map do |key, localized_concept|
          [key, localized_concept.to_yaml_hash]
        end.to_h
      end

      # Hash#transform_keys is not available in Ruby 2.4
      # so we have to do this ourselves :(
      # symbolize hash keys
      def stringify_keys(hash)
        result = {}
        hash.each_pair do |key, value|
          result[key.to_s] = if value.is_a?(Hash)
                               stringify_keys(value)
                             else
                               value
                             end
        end
        result
      end
    end
  end
end
