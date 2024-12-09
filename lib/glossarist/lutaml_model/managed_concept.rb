require_relative "localized_concept"

module Glossarist
  module LutamlModel
    class ManagedConcept < Lutaml::Model::Serializable
      attribute :id, :integer
      attribute :uuid, :string
      attribute :related, RelatedConcept
      attribute :status, :string, values: Glossarist::GlossaryDefinition::CONCEPT_STATUSES
      attribute :dates, ConceptDate, collection: true
      attribute :localized_concept, :hash
      attribute :groups, :string, collection: true
      attribute :sources, ConceptSource
      attribute :localizations, :hash
      attribute :localization, :string
      attribute :add_localization, :string
      # attribute :localized_concept_class, LocalizedConcept
      # attribute :uuid_namespace, :string, values: Glossarist::Utilities::UUID::OID_NAMESPACE
      attribute :attributes, :hash
      attribute :data, :hash

      alias :l10n :localization
      alias :add_l10n :add_localization
      alias :termid= :id=
      alias :identifier= :id=

      yaml do
        map :id, to: :id
        map :uuid, to: :uuid
        map :related, to: :related
        map :status, to: :status
        map :dates, to: :dates
        map :localized_concept, to: :localized_concept
        map :groups, to: :groups
        map :sources, to: :sources
        map :localizations, to: :localizations
        map :localization, to: :localization
        map :add_localization, to: :add_localization
        # map :localized_concept_class, :localized_concept_class
        map :uuid_namespace, to: :uuid_namespace
        map :attributes, to: :attributes
        map :data, to: :data
      end
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

    def localized_concepts=(localized_concepts)
      return unless localized_concepts

      if localized_concepts.is_a?(Hash)
        @localized_concepts = stringify_keys(localized_concepts)
      else
        localized_concepts.each do |localized_concept_hash|
          lang = localized_concept_hash["language_code"].to_s

          localized_concept = add_localization(
            @localized_concept_class.new(localized_concept_hash["data"] || localized_concept_hash),
          )

          @localized_concepts[lang] = localization(lang).uuid

          localized_concept
        end
      end
    end

    def sources=(sources)
      @sources = sources&.map do |source|
        ConceptSource.new(source)
      end || []
    end

    def localizations=(localizations)
      return unless localizations

      @localizations = {}

      localizations.each do |localized_concept|
        unless localized_concept.is_a?(@localized_concept_class)
          localized_concept = @localized_concept_class.new(
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
  end
end
# values: Glossarist::Utilities::UUID.uuid_v5(@uuid_namespace, name)