# frozen_string_literal: true

module Glossarist
  module V3
    # DefinitionType — ISO 704:2022 §5.3 definition strategy constants.
    module DefinitionType
      INTENSIONAL = "intensional"
      EXTENSIONAL = "extensional"
      PARTITIVE = "partitive"
      TRANSLATED = "translated"

      DEFAULT = INTENSIONAL

      VALUES = Glossarist::GlossaryDefinition::DEFINITION_TYPE_VALUES.freeze
    end
  end
end
