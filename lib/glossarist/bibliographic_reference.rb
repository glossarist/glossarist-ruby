# frozen_string_literal: true

module Glossarist
  class BibliographicReference
    attr_reader :anchor, :location

    def initialize(anchor:, location: nil)
      @anchor = anchor
      @location = location
    end

    def dedup_key
      anchor
    end
  end
end
