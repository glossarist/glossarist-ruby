# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module Glossarist
  class Concept < Model
    # Concept ID.
    # @return [String]
    attr_accessor :id

    # All localizations for this concept.
    #
    # Keys are language codes and values are instances of {LocalizedConcept}.
    # @return [Hash<String, LocalizedConcept>]
    attr_reader :localizations

    def initialize(*)
      @localizations = {}
      @sources = []
      @related = []

      super
    end

    # All sources for this concept.
    # @return [Array<ConceptSource>]
    attr_reader :sources

    def sources=(sources)
      @sources = sources&.map do |source|
        ConceptSource.new(source)
      end
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
        "termid" => id,
        "term" => default_designation,
        "sources" => sources&.map(&:to_h),
        "related" => related&.map(&:to_h),
      }
      .compact
      .merge(localizations.transform_values(&:to_h))
    end

    # @deprecated For legacy reasons only.
    #   Implicit conversion (i.e. {#to_hash} alias) will be removed soon.
    alias :to_hash :to_h

    # rubocop:disable Metrics/AbcSize, Style/RescueModifier
    def self.from_h(hash)
      new.tap do |concept|
        concept.id = hash.dig("termid")
        concept.sources = hash.dig("sources")

        hash.values
          .grep(Hash)
          .map { |subhash| LocalizedConcept.from_h(subhash) rescue nil }
          .compact
          .each { |lc| concept.add_l10n lc }

        concept.related = hash.dig("related") || []
      end
    end
    # rubocop:enable Metrics/AbcSize, Style/RescueModifier

    def default_designation
      localized = localization("eng") || localizations.values.first
      localized&.terms&.first&.designation
    end

    # All Related Concepts
    # @return [Array<RelatedConcept>]
    def related
      @related.empty? ? nil : @related
    end

    def related=(related)
      @related = related.map { |r| RelatedConcept.new(r) }
    end

    Glossarist::RelatedConcept::TYPES.each do |type|
      # List of related concepts of the specified type.
      # @return [Array<RelatedConcept>]
      define_method("#{type}_concepts") do
        related&.select { |concept| concept.type == type } || []
      end
    end
  end
end
