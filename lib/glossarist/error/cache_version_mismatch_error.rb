module Glossarist
  class CacheVersionMismatchError < Error
    def initialize(cache_dir, expected, actual)
      super("Relaton cache version mismatch in '#{cache_dir}': " \
            "expected '#{expected}', got '#{actual}'")
    end
  end
end
