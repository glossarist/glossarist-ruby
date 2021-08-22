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

    # List of concepts deprecated by this one.
    # @return [Array<Ref>]
    attr_accessor :deprecated_concepts

    # List of concepts superseded by this one.
    # @return [Array<Ref>]
    attr_accessor :superseded_concepts

    # List of concepts narrower than this one.
    # @return [Array<Ref>]
    attr_accessor :narrower_concepts

    # List of concepts broader than this one.
    # @return [Array<Ref>]
    attr_accessor :broader_concepts

    # List of concepts equivalent to this one.
    # @return [Array<Ref>]
    attr_accessor :equivalent_concepts

    # List of concepts comparable to this one.
    # @todo Maybe attribute name could be improved.
    # @return [Array<Ref>]
    attr_accessor :comparable_concepts

    # List of concepts contrasting to this one.
    # @return [Array<Ref>]
    attr_accessor :contrasting_concepts

    # List of "see also" concepts related to this one.
    # @return [Array<Ref>]
    attr_accessor :see_also_concepts

    # :nodoc:
    CONCEPT_RELATIONS = {
      deprecated_concepts: {serialize_as: "deprecates"},
      superseded_concepts: {serialize_as: "supersedes"},
      narrower_concepts: {serialize_as: "narrower"},
      broader_concepts: {serialize_as: "broader"},
      equivalent_concepts: {serialize_as: "equivalent"},
      comparable_concepts: {serialize_as: "compare"},
      contrasting_concepts: {serialize_as: "contrast"},
      see_also_concepts: {serialize_as: "see"},
    }.freeze

    def initialize(*)
      @localizations = {}
      CONCEPT_RELATIONS.keys.each { |cr| set_attribute cr, [] }
      super
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
        "related" => related_concepts,
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

        hash.values
          .grep(Hash)
          .map { |subhash| LocalizedConcept.from_h(subhash) rescue nil }
          .compact
          .each { |lc| concept.add_l10n lc }

        concept.superseded_concepts = hash.dig("related") || []
      end
    end
    # rubocop:enable Metrics/AbcSize, Style/RescueModifier

    def default_designation
      localized = localization("eng") || localizations.values.first
      localized&.terms&.first&.designation
    end

    def related_concepts
      # TODO Someday other relation types too
      arr = [superseded_concepts].flatten.compact
      arr.empty? ? nil : arr
    end
  end
end
