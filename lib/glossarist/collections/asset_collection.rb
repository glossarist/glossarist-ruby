# frozen_string_literal: true

module Glossarist
  module Collections
    class AssetCollection < Set

      # assets read from the directory
      attr_accessor :assets

      def initialize(assets)
        @assets = assets

        super
      end
    end
  end
end
