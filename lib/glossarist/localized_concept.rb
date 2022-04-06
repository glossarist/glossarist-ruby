# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module Glossarist
  class LocalizedConcept < Model
    # Needs to be identical with {Concept#id}.
    # @todo Here for legacy reasons.  Will be removed eventually.
    attr_accessor :id

    # ISO 639-2 code for terminology.
    # @see https://www.loc.gov/standards/iso639-2/php/code_list.php code list
    # @return [String]
    attr_accessor :language_code

    # Concept designations.
    # @todo Alias +terms+ exists only for legacy reasons and will be removed.
    # @return [Array<Designations::Base>]
    attr_accessor :designations
    alias :terms :designations
    alias :terms= :designations=

    # @return [Array<String>]
    attr_accessor :notes

    # @return [Array<String>]
    attr_accessor :examples

    # Concept definition.
    # @todo Support multiple definitions.
    # @return [String]
    attr_accessor :definition

    # List of authorative sources.
    # @todo Alias +authoritative_source+ exists for legacy reasons and may be
    #   removed.
    # @return [Array<Ref>]
    attr_accessor :sources
    alias :authoritative_source :sources
    alias :authoritative_source= :sources=

    # Must be one of the following:
    # +notValid+, +valid+, +superseded+, +retired+.
    # @todo Proper type checking.
    # @note Works with strings, but soon they may be replaced with symbols.
    # @return [String]
    attr_accessor :entry_status

    # Must be one of the following:
    # +preferred+, +admitted+, +deprecated+.
    # @todo Proper type checking.
    # @note Works with strings, but soon they may be replaced with symbols.
    # @return [String]
    attr_accessor :classification

    attr_accessor :review_date
    attr_accessor :review_decision_date
    attr_accessor :review_decision_event

    attr_accessor :date_accepted
    attr_accessor :date_amended

    def initialize(*)
      @examples = []
      @notes = []
      @designations = []
      @sources = []
      super
    end

    def to_h # rubocop:disable Metrics/MethodLength
      {
        "id" => id,
        "terms" => (terms&.map(&:to_h) || []),
        "definition" => definition,
        "language_code" => language_code,
        "notes" => notes,
        "examples" => examples,
        "entry_status" => entry_status,
        "classification" => classification,
        "authoritative_source" => sources&.map(&:to_h),
        "date_accepted" => date_accepted,
        "date_amended" => date_amended,
        "review_date" => review_date,
        "review_decision_date" => review_decision_date,
        "review_decision_event" => review_decision_event,
      }.compact
    end

    def self.from_h(hash)
      terms = hash["terms"]&.map { |h| Designation::Base.from_h(h) } || []
      sources = hash["authoritative_source"]&.map { |h| Ref.from_h(h) }
      super(hash.merge({"terms" => terms, "sources" => sources}))
    end

    # @deprecated For legacy reasons only.
    #   Implicit conversion (i.e. {#to_hash} alias) will be removed soon.
    alias :to_hash :to_h
  end
end
