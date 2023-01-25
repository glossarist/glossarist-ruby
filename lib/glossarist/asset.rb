# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module Glossarist
  class Asset
    attr_accessor :path

    def initialize(path)
      @path = path
    end

    def eql?(asset)
      path == asset.path
    end

    def hash
      path.hash
    end
  end
end
