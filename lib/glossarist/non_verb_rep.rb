# frozen_string_literal: true

module Glossarist
  class NonVerbRep
    attr_accessor :image
    attr_accessor :table
    attr_accessor :formula

    # @return [Array<ConceptSource>]
    attr_reader :sources

    def sources=(sources)
      @sources = sources&.map do |source|
        ConceptSource.new(source)
      end
    end
  end
end
