# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module Glossarist
  class Concept < Model
    # Concept ID.
    # @return [String]
    attr_reader :id

    attr_writer :uuid

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

    attr_accessor :lineage_source
    attr_accessor :lineage_source_similarity

    attr_accessor :release

    def initialize(*args)
      @localizations = {}
      @sources = Glossarist::Collections::Collection.new(klass: ConceptSource)
      @related = Glossarist::Collections::Collection.new(klass: RelatedConcept)
      @definition = Glossarist::Collections::Collection.new(klass: DetailedDefinition)
      @notes = Glossarist::Collections::Collection.new(klass: DetailedDefinition)
      @examples = Glossarist::Collections::Collection.new(klass: DetailedDefinition)
      @dates = Glossarist::Collections::Collection.new(klass: ConceptDate)

      @designations = Glossarist::Collections::DesignationCollection.new
      @extension_attributes = {}

      normalize_args(args)

      super
    end

    def uuid
      @uuid ||= Glossarist::Utilities::UUID.uuid_v5(
        Glossarist::Utilities::UUID::OID_NAMESPACE,
        to_h.to_yaml,
      )
    end

    def id=(id)
      # Some of the glossaries that are not generated using glossarist, contains ids that are integers 
      # so adding a temporary check until every glossary is updated using glossarist.
      if !id.nil? && (id.is_a?(String) || id.is_a?(Integer))
        @id = id
      else
        raise(Glossarist::Error, "Expect id to be a String or Integer, Got #{id.class} (#{id})")
      end
    end
    alias :termid= :id=
    alias :identifier= :id=

    # List of authorative sources.
    # @todo Alias +authoritative_source+ exists for legacy reasons and may be
    #   removed.
    # @return [Array<ConceptSource>]
    attr_reader :sources
    alias :authoritative_source :sources

    # return [Array<ConceptDate>]
    attr_reader :dates

    def examples=(examples)
      @examples.clear!
      examples&.each { |example| @examples << example }
    end

    def notes=(notes)
      @notes.clear!
      notes&.each { |note| @notes << note }
    end

    def definition=(definition)
      @definition.clear!
      definition&.each { |definition| @definition << definition }
    end

    def designations=(designations)
      @designations.clear!
      designations&.each { |designation| @designations << designation }
    end

    alias :terms= :designations=

    def preferred_designations
      @designations.select(&:preferred?)
    end
    alias :preferred_terms :preferred_designations

    def dates=(dates)
      @dates.clear!
      dates&.each { |date| @dates << date }
    end

    def sources=(sources)
      @sources.clear!
      sources&.each { |source| @sources << source }
    end

    def authoritative_source=(sources)
      self.sources = sources&.map do |source|
        source.merge({ "type" => "authoritative" })
      end
    end

    def to_h
      {
        "data" => {
          "dates" => dates&.map(&:to_h),
          "definition" => definition&.map(&:to_h),
          "examples" => examples&.map(&:to_h),
          "id" => id,
          "lineage_source_similarity" => lineage_source_similarity,
          "notes" => notes&.map(&:to_h),
          "release" => release,
          "sources" => sources.empty? ? nil : sources&.map(&:to_h),
          "terms" => (terms&.map(&:to_h) || []),
          "related" => related&.map(&:to_h),
        }.compact,
      }.compact
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
      @related.clear!
      related&.each { |r| @related << r }
    end

    Glossarist::GlossaryDefinition::CONCEPT_DATE_TYPES.each do |type|
      # Sets the ConceptDate and add it to dates list of the specified type.
      define_method("date_#{type}=") do |date|
        date_hash = {
          "type" => type,
          "date" => date,
        }
        @dates ||= []
        @dates << ConceptDate.new(date_hash)
      end
    end

    def normalize_args(args)
      args.each do |arg|
        data = arg.delete("data")

        arg.merge!(data) if data
      end
    end
  end
end
