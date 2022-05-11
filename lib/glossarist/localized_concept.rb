# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module Glossarist
  class LocalizedConcept < Concept
    # ISO 639-2 code for terminology.
    # @see https://www.loc.gov/standards/iso639-2/php/code_list.php code list
    # @return [String]
    attr_accessor :language_code

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

    def initialize(*)
      @examples = []

      super
    end

    def to_h # rubocop:disable Metrics/MethodLength
      super.merge({
        "language_code" => language_code,
        "entry_status" => entry_status,
        "sources" => sources.empty? ? nil : sources&.map(&:to_h),
        "classification" => classification,
        "dates" => dates&.map(&:to_h),
        "review_date" => review_date,
        "review_decision_date" => review_decision_date,
        "review_decision_event" => review_decision_event,
      }.compact)
    end

    def self.from_h(hash)
      terms = hash["terms"]&.map { |h| Designation::Base.from_h(h) } || []
      sources = hash["authoritative_source"]&.each { |source| source.merge({ "type" => "authoritative"}) }

      super(hash.merge({"terms" => terms, "sources" => sources}))
    end

    # @deprecated For legacy reasons only.
    #   Implicit conversion (i.e. {#to_hash} alias) will be removed soon.
    alias :to_hash :to_h
  end
end
