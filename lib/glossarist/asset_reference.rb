# frozen_string_literal: true

module Glossarist
  class AssetReference
    attr_reader :path, :location

    def initialize(path:, location: nil)
      @path = path
      @location = location
    end

    def dedup_key
      path
    end
  end
end
