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
  end
end
