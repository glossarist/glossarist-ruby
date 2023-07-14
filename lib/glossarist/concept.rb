# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module Glossarist
  class Concept < Model
    # Concept ID.
    # @return [String]
    attr_reader :id

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

    # Contains list of extended attributes
    attr_accessor :extension_attributes

    def initialize(*)
      @localizations = {}
      @sources = []
      @related = []
      @notes = []
      @designations = []
      @extension_attributes = {}

      super
    end

    def id=(id)
      raise(Glossarist::Error, "id must be a string") unless id.is_a?(String) || id.nil?

      @id = id
    end
    alias :termid= :id=

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
      end || []
    end

    def authoritative_source=(sources)
      self.sources = sources&.map do |source|
        source.merge({ "type" => "authoritative" })
      end
    end

    def to_h
      {
        "id" => id,
        "related" => related&.map(&:to_h),
        "terms" => (terms&.map(&:to_h) || []),
        "definition" => definition&.map(&:to_h),
        "notes" => notes&.map(&:to_h),
        "examples" => examples&.map(&:to_h),
      }
      .compact
    end

    # @deprecated For legacy reasons only.
    #   Implicit conversion (i.e. {#to_hash} alias) will be removed soon.
    alias :to_hash :to_h

    # rubocop:disable Metrics/AbcSize, Style/RescueModifier
    def self.from_h(hash)
      new.tap do |concept|
        concept.id = hash.dig("termid") || hash.dig("id")
        concept.sources = hash.dig("sources")
        concept.related = hash.dig("related")
        concept.definition = hash.dig("definition")

        hash.values
          .grep(Hash)
          .map { |subhash| Config.class_for(:localized_concept).from_h(subhash) rescue nil }
          .compact

        concept.related = hash.dig("related") || []
      end
    end
    # rubocop:enable Metrics/AbcSize, Style/RescueModifier

    # All Related Concepts
    # @return [Array<RelatedConcept>]
    def related
      @related.empty? ? nil : @related
    end

    def related=(related)
      @related = related&.map { |r| RelatedConcept.new(r) } || []
    end
  end
end
