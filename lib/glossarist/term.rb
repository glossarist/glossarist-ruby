# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module Glossarist
  class Term < Model
    # Term acronym
    attr_accessor :acronym

    # Term definition.
    attr_accessor :definition

    # List of synonyms.
    # @return [Array<String>]
    attr_accessor :synonyms

    def to_h
      {
        "acronym" => acronym,
        "definition" => definition,
        "synonyms" => synonyms
      }.compact
    end

    def self.from_h(hash)
      _, definition, acronym = treat_acronym(hash["definition"])
      hash["definition"] = definition
      hash["acronym"] = acronym.gsub(/\(|\)/, '') if acronym

      super(hash)
    end

    private

    def self.treat_acronym(term_def)
      return [nil, term_def.strip, nil] if term_def !~ /.+\(.+?\)$/

      term_def.match(/(.+?)(\(.+\))$/).to_a
    end
  end
end
