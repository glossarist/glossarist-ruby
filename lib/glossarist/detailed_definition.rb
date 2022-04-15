# frozen_string_literal: true

module Glossarist
  class DetailedDefinition < Model
    attr_accessor :content

    attr_reader :sources

    def sources=(sources)
      @sources = sources.map { |s| ConceptSource.new(s) }
    end

    def to_h
      {
        "content" => content,
        "sources" => sources&.map(&:to_h),
      }.compact
    end
  end
end
