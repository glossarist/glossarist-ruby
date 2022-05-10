# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module Glossarist
  class Concept < Model
    # Concept ID.
    # @return [String]
    attr_accessor :id
    alias :termid= :id=

    # All localizations for this concept.
    #
    # Keys are language codes and values are instances of {LocalizedConcept}.
    # @return [Hash<String, LocalizedConcept>]
    attr_reader :localizations

    # Concept designations.
    # @todo Alias +terms+ exists only for legacy reasons and will be removed.
    # @return [Array<Designations::Base>]
    attr_reader :designations
    alias :terms :designations

    # <<BasicDocument>>LocalizedString
    # @return [String]
    attr_accessor :domain

    # <<BasicDocument>>LocalizedString
    # @return [String]
    attr_accessor :subject

    # Concept definition.
    # @return [Array<DetailedDefinition>]
    attr_reader :definition

    # Non verbal representation of the concept.
    # @return [NonVerbRep]
    attr_accessor :non_verb_rep

    # Concept notes
    # @return [Array<DetailedDefinition>]
    attr_reader :notes

    # Concept examples
    # @return [Array<DetailedDefinition>]
    attr_reader :examples

    def initialize(*)
      @localizations = {}
      @sources = []
      @related = []
      @notes = []
      @designations = []

      super
    end

    # List of authorative sources.
    # @todo Alias +authoritative_source+ exists for legacy reasons and may be
    #   removed.
    # @return [Array<ConceptSource>]
    attr_reader :sources
    alias :authoritative_source :sources

    # return [Array<ConceptDate>]
    attr_reader :dates

    def examples=(examples)
      @examples = examples&.map { |e| DetailedDefinition.new(e) }
    end

    def notes=(notes)
      @notes = notes&.map { |n| DetailedDefinition.new(n) }
    end

    def definition=(definition)
      @definition = definition&.map { |d| DetailedDefinition.new(d) }
    end

    def designations=(designations)
      @designations = designations&.map do |designation|
        Designation::Base.from_h(designation)
      end
    end

    alias :terms= :designations=

    def dates=(dates)
      @dates = dates&.map { |d| ConceptDate.new(d) }
    end

    def sources=(sources)
      @sources = sources&.map do |source|
        ConceptSource.new(source)
      end
    end

    def authoritative_source=(sources)
      self.sources = sources&.map do |source|
        source.merge({ "type" => "authoritative" })
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
        "id" => id,
        "termid" => id,
        "term" => default_designation,
        "sources" => sources&.map(&:to_h),
        "related" => related&.map(&:to_h),

        "terms" => (terms&.map(&:to_h) || []),
        "definition" => definition&.map(&:to_h),
        "notes" => notes&.map(&:to_h),
        "examples" => examples&.map(&:to_h),
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
        concept.related = hash.dig("related")
        concept.definition = hash.dig("definition")

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
      binding.pry
      @related = related&.map { |r| RelatedConcept.new(r) }
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
