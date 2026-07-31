# frozen_string_literal: true

module Glossarist
  module V3
    # ConceptType — ISO 704:2022 §5.2-5.3 general vs individual concept.
    module ConceptType
      GENERAL = "general"
      INDIVIDUAL = "individual"

      DEFAULT = GENERAL

      VALUES = [GENERAL, INDIVIDUAL].freeze
    end
  end
end
