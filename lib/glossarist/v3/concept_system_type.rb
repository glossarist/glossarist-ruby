# frozen_string_literal: true

module Glossarist
  module V3
    # ConceptSystemType — ISO 12620 A.7.1 concept system type enum.
    module ConceptSystemType
      GENERIC = "generic"
      PARTITIVE = "partitive"
      SEQUENTIAL = "sequential"
      ASSOCIATIVE = "associative"
      MIXED = "mixed"

      VALUES = [GENERIC, PARTITIVE, SEQUENTIAL, ASSOCIATIVE, MIXED].freeze
    end
  end
end
