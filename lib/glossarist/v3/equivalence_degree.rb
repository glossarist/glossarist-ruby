# frozen_string_literal: true

module Glossarist
  module V3
    # EquivalenceDegree — ISO 704:2022 §7.7.3 cross-language equivalence.
    module EquivalenceDegree
      FULL = "full"
      PARTIAL = "partial"
      NONE = "none"
      DIRECTIONAL = "directional"

      DEFAULT = FULL

      VALUES = [FULL, PARTIAL, NONE, DIRECTIONAL].freeze
    end
  end
end
