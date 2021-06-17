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
    # @todo Right now accepts hashes for legacy reasons, but they will be
    #   replaced with dedicated classes.
    # @return [Array<Hash>]
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

    # @todo Right now accepts hashes for legacy reasons, but they will be
    #   replaced with dedicated classes.
    # @return [Hash]
    attr_accessor :authoritative_source

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

    # @todo Here for legacy reasons.  Will be moved to Concept.
    # @todo Right now is an array of hashes for legacy reasons, but these hashes
    #    will be replaced with some dedicated class.
    # @todo Should be read-only, but for now it is not for legacy reasons.
    #    Don't use the setter.
    # @return [Array<Hash>]
    attr_accessor :superseded_concepts

    def initialize(*)
      @examples = []
      @notes = []
      @designations = []
      @superseded_concepts = []
      super
    end

    def to_h # rubocop:disable Metrics/MethodLength
      {
        "id" => id,
        "terms" => terms,
        "definition" => definition,
        "language_code" => language_code,
        "notes" => notes,
        "examples" => examples,
        "entry_status" => entry_status,
        "classification" => classification,
        "authoritative_source" => authoritative_source,
        "date_accepted" => date_accepted,
        "date_amended" => date_amended,
        "review_date" => review_date,
        "review_decision_date" => review_decision_date,
        "review_decision_event" => review_decision_event,
      }.compact
    end

    # @deprecated For legacy reasons only.
    #   Implicit conversion (i.e. {#to_hash} alias) will be removed soon.
    alias :to_hash :to_h
  end
end
