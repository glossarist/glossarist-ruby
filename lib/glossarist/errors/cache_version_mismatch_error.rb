# frozen_string_literal: true

module Glossarist
  module Errors
    class CacheVersionMismatchError < Base
      def initialize(cache_dir, expected, actual)
        super("Relaton cache version mismatch in '#{cache_dir}': " \
              "expected '#{expected}', got '#{actual}'")
      end
    end
  end
end
