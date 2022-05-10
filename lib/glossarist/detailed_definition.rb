# frozen_string_literal: true

module Glossarist
  class DetailedDefinition < Model

    def initialize(attributes = {})
      if attributes.is_a?(Hash)
        super
      else
        self.content = attributes
      end
    end

    # @return [String]
    attr_accessor :content

    # @return [Array<ConceptSource>]
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
