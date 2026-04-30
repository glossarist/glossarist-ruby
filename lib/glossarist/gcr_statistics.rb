# frozen_string_literal: true

module Glossarist
  class GcrStatistics
    LANG_CODES = %w[eng ara deu fra spa ita jpn kor pol por srp swe zho rus fin dan nld msa nob nno].freeze

    attr_accessor :total_concepts, :languages, :concepts_by_status,
                  :concepts_with_definitions, :concepts_with_sources

    def initialize(attrs = {})
      @total_concepts = attrs[:total_concepts] || 0
      @languages = attrs[:languages] || []
      @concepts_by_status = attrs[:concepts_by_status] || {}
      @concepts_with_definitions = attrs[:concepts_with_definitions] || 0
      @concepts_with_sources = attrs[:concepts_with_sources] || 0
    end

    def self.from_concepts(concepts)
      languages = Set.new
      by_status = Hash.new(0)
      with_defs = 0
      with_sources = 0

      concepts.each do |concept|
        LANG_CODES.each do |lang|
          next unless concept[lang].is_a?(Hash)
          languages << lang

          status = concept[lang]["entry_status"]
          by_status[status] += 1 if status

          if concept[lang]["definition"]
            with_defs += 1
          end

          if concept[lang]["sources"]
            with_sources += 1
          end
        end
      end

      new(
        total_concepts: concepts.length,
        languages: languages.sort,
        concepts_by_status: by_status,
        concepts_with_definitions: with_defs,
        concepts_with_sources: with_sources,
      )
    end

    def to_h
      {
        "total_concepts" => total_concepts,
        "languages" => languages,
        "concepts_by_status" => concepts_by_status,
        "concepts_with_definitions" => concepts_with_definitions,
        "concepts_with_sources" => concepts_with_sources,
      }
    end
  end
end
