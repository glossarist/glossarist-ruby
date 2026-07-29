# frozen_string_literal: true

require "yaml"

module Glossarist
  module GlossaryDefinition
    config = YAML.load_file(File.expand_path("../../config.yml",
                                             __dir__)) || {}

    CONCEPT_SOURCE_STATUSES = config.dig("concept_source", "status").freeze

    CONCEPT_SOURCE_TYPES = config.dig("concept_source", "type").freeze

    RELATED_CONCEPT_TYPES = config.dig("related_concept", "type").freeze

    ABBREVIATION_TYPES = config.dig("abbreviation", "type").freeze

    GRAMMAR_INFO_BOOLEAN_ATTRIBUTES = config.dig("grammar_info",
                                                 "boolean_attribute").freeze

    GRAMMAR_INFO_GENDERS = config.dig("grammar_info", "gender").freeze

    GRAMMAR_INFO_NUMBERS = config.dig("grammar_info", "number").freeze

    DESIGNATION_BASE_NORMATIVE_STATUSES = config.dig("designation", "base",
                                                     "normative_status").freeze

    CONCEPT_DATE_TYPES = config.dig("concept_date", "type").freeze

    CONCEPT_STATUSES = config.dig("concept", "status").freeze

    DESIGNATION_RELATIONSHIP_TYPES = config.dig("designation",
                                                "relationship_type")&.freeze

    ISO12620_TERM_TYPES = config.dig("iso12620", "term_type").freeze

    # PartitiveRelation redesign (TODO.partitive-relation-v2).
    COMPLETENESS_VALUES = config.dig("completeness", "value").freeze

    # Member presence/count values for any n-ary relation member
    # (PartitiveMember, GenericMember — both inherit ConceptSystemMember).
    # The config key is `multiplicity:` because presence + count encode
    # ISO 704:2022 multiplicity in the MECE decomposition; the constants
    # are named for their consumers (ConceptSystemMember fields).
    MEMBER_PRESENCE_VALUES =
      config.dig("multiplicity", "presence").freeze

    MEMBER_COUNT_VALUES =
      config.dig("multiplicity", "count").freeze

    # ISO 704:2022 §5.3 definition strategies.
    DEFINITION_TYPE_VALUES =
      config.dig("definition_type", "value").freeze

    # Wire discriminator for per-file n-ary relation files.
    RELATION_TYPE_VALUES =
      config.dig("relation_type", "value").freeze
  end
end
