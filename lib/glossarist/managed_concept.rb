# frozen_string_literal: true

module Glossarist
  class ManagedConcept < Model
    include Glossarist::Utilities::Enum

    # @return [String]
    attr_accessor :id
    alias :termid= :id=

    # @return [Array<RelatedConcept>]
    attr_reader :related

    # @return [String]
    register_enum :status, Glossarist::GlossaryDefinition::CONCEPT_STATUSES

    # return [Array<ConceptDate>]
    attr_reader :dates

    # return [Array<LocalizedConcept>]
    attr_reader :localized_concepts

    # All localizations for this concept.
    #
    # Keys are language codes and values are instances of {LocalizedConcept}.
    # @return [Hash<String, LocalizedConcept>]
    attr_accessor :localizations

    def initialize(attributes = {})
      @localizations = {}
      self.localized_concepts = attributes.values.grep(Hash)

      super(attributes.slice(*managed_concept_attributes))
    end

    def localized_concepts=(localized_concepts_hash)
      @localized_concepts = localized_concepts_hash.map { |l| LocalizedConcept.new(l) }.compact

      @localized_concepts.each do |l|
        add_l10n(l)
      end

      @localized_concepts
    end

    def related=(related)
      binding.pry
      @related = related&.map { |r| RelatedConcept.new(r) }
    end

    def dates=(dates)
      @dates = dates&.map { |d| ConceptDate.new(d) }
    end

    # Adds concept localization.
    # @param localized_concept [LocalizedConcept]
    def add_localization(localized_concept)
      lang = localized_concept.language_code
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
        "related" => related&.map(&:to_h),
        "status" => status,
        "dates" => dates&.map(&:to_h),
        "localized_concepts" => localized_concepts&.to_h,
      }.compact
    end

    def managed_concept_attributes
      %w[
        termid
        related
        status
        dates
      ].compact
    end
  end
end
