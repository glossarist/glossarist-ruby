# frozen_string_literal: true

module Glossarist
  module V3
    # DefinitionType — ISO 704:2022 §5.3 definition strategy constants.
    #
    # SSOT for the set of definition-type values. `DetailedDefinition#type`
    # reads `VALUES` from here, not from `GlossaryDefinition`. The config
    # (config.yml) feeds `GlossaryDefinition::DEFINITION_TYPE_VALUES`, which
    # is consumed here so the source-of-truth chain is:
    #
    #     config.yml → GlossaryDefinition::DEFINITION_TYPE_VALUES
    #                → DefinitionType::VALUES  (consumer-facing)
    #                → DetailedDefinition#type (model attribute)
    module DefinitionType
      INTENSIONAL = "intensional"
      EXTENSIONAL = "extensional"
      PARTITIVE = "partitive"
      TRANSLATED = "translated"

      DEFAULT = INTENSIONAL

      VALUES = Glossarist::GlossaryDefinition::DEFINITION_TYPE_VALUES.freeze

      def self.valid?(value)
        VALUES.include?(value)
      end
    end
  end
end
