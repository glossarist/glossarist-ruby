# frozen_string_literal: true

require "yaml"

module Glossarist
  class GlossaryDefinition
    config = YAML.load_file(File.expand_path("../../../config.yml", __FILE__)) || {}

    DEFAULT_CONFIG = {
      "concept_source" => {
        "status" => %w[
          identical
          modified
          restyle
          context-added
          generalisation
          specialisation
          unspecified
        ],

        "type" => %w[
          authoritative
          lineage
        ],
      },

      "related_concept" => {
        "type" => %w[
          deprecates
          supersedes
          superseded_by
          narrower
          broader
          equivalent
          compare
          contrast
          see
        ],
      },

      "abbreviation" => {
        "type" => %w[
          truncation
          acronym
          initialism
        ],
      },

      "grammar_info" => {
        "boolean_attribute" => %w[
          preposition
          participle
          adj
          verb
          adverb
          noun
        ],

        # m => masculine
        # f => feminine
        # n => neuter
        # c => common
        # using initial letter because this is how it is used in iev-data
        "gender" => %w[
          m
          f
          n
          c
        ],

        "number" => %w[
          singular
          dual
          plural
        ],
      },

      "designation" => {
        "normative_status" => %w[
          preferred
          admitted
          deprecated
        ],
      },
    }.freeze

    CONCEPT_SOURCE_STATUSES = (
      config.dig("concept_source", "status") ||
      DEFAULT_CONFIG.dig("concept_source", "status")
    ).freeze

    CONCEPT_SOURCE_TYPES = (
      config.dig("concept_source", "type") ||
      DEFAULT_CONFIG.dig("concept_source", "type")
    ).freeze

    RELATED_CONCEPT_TYPES = (
      config.dig("related_concept", "type") ||
      DEFAULT_CONFIG.dig("related_concept", "type")
    ).freeze

    ABBREVIATION_TYPES = (
      config.dig("abbreviation", "type") ||
      DEFAULT_CONFIG.dig("abbreviation", "type")
    ).freeze

    GRAMMAR_INFO_BOOLEAN_ATTRIBUTES = (
      config.dig("grammar_info", "boolean_attribute") ||
      DEFAULT_CONFIG.dig("grammar_info", "boolean_attribute")
    ).freeze

    GRAMMAR_INFO_GENDERS = (
      config.dig("grammar_info", "gender") ||
      DEFAULT_CONFIG.dig("grammar_info", "gender")
    ).freeze

    GRAMMAR_INFO_NUMBERS = (
      config.dig("grammar_info", "number") ||
      DEFAULT_CONFIG.dig("grammar_info", "number")
    ).freeze

    DESIGNATION_NORMATIVE_STATUSES = (
      config.dig("designation", "normative_status") ||
      DEFAULT_CONFIG.dig("designation", "normative_status")
    ).freeze
  end
end
