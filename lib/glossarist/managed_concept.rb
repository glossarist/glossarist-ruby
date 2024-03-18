# frozen_string_literal: true

module Glossarist
  class ManagedConcept < Model
    include Glossarist::Utilities::Enum
    include Glossarist::Utilities::CommonFunctions

    # @return [String]
    attr_accessor :id
    alias :termid= :id=
    alias :identifier= :id=

    attr_accessor :uuid

    # @return [Array<RelatedConcept>]
    attr_reader :related

    # @return [String]
    register_enum :status, Glossarist::GlossaryDefinition::CONCEPT_STATUSES

    # return [Array<ConceptDate>]
    attr_reader :dates

    # return [Array<LocalizedConcept>]
    attr_reader :localized_concepts

    # Concept group
    # @return [Array<String>]
    attr_reader :groups

    # List of authorative sources.
    # @return [Array<ConceptSource>]
    attr_reader :sources

    # All localizations for this concept.
    #
    # Keys are language codes and values are instances of {LocalizedConcept}.
    # @return [Hash<String, LocalizedConcept>]
    attr_reader :localizations

    def initialize(attributes = {})
      @localizations = {}
      @localized_concepts = {}
      @localized_concept_class = Config.class_for(:localized_concept)
      @uuid_namespace = Glossarist::Utilities::UUID::OID_NAMESPACE

      attributes = symbolize_keys(attributes)
      @uuid = attributes[:uuid]

      data = attributes.delete(:data) || {}
      data["groups"] = attributes[:groups]
      data["status"] = attributes[:status]

      data = symbolize_keys(data.compact)

      super(slice_keys(data, managed_concept_attributes))
    end

    def uuid
      @uuid ||= Glossarist::Utilities::UUID.uuid_v5(@uuid_namespace, to_h.to_yaml)
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
        localized_concepts.each do |localized_concept|
          lang = localized_concept["language_code"].to_s

          @localized_concepts[lang] = Glossarist::Utilities::UUID.uuid_v5(@uuid_namespace, localized_concept.to_h.to_yaml)

          add_localization(
            @localized_concept_class.new(localized_concept["data"] || localized_concept),
          )
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

    def localizations_hash
      @localizations.map do |key, localized_concept|
        [key, localized_concept.to_h]
      end.to_h
    end

    # Adds concept localization.
    # @param localized_concept [LocalizedConcept]
    def add_localization(localized_concept)
      lang = localized_concept.language_code
      @localized_concepts[lang] = @localized_concepts[lang] || localized_concept.uuid
      localizations.store(lang, localized_concept)
    end

    alias :add_l10n :add_localization

    # Returns concept localization.
    # @param lang [String] language code
    # @return [LocalizedConcept]
    def localization(lang)
      localizations[lang]
    end

    alias :l10n :localization

    def to_h
      {
        "data" => {
          "identifier" => id,
          "localized_concepts" => localized_concepts.empty? ? nil : localized_concepts,
          "groups" => groups,
          "sources" => sources&.map(&:to_h),
        }.compact,
      }.compact
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

    def date_accepted=(date)
      date_hash = {
        "type" => "accepted",
        "date" => date,
      }

      @dates ||= []
      @dates << ConceptDate.new(date_hash)
    end

    def date_accepted
      @dates.find { |date| date.accepted? }
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
  end
end
