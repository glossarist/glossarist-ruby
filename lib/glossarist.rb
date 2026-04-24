# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

require "psych"
require "thor"
require "lutaml/model"

require_relative "glossarist/glossary_definition"

module Glossarist
  autoload :Asset,                    "glossarist/asset"
  autoload :Citation,                 "glossarist/citation"
  autoload :Collection,               "glossarist/collection"
  autoload :Concept,                  "glossarist/concept"
  autoload :ConceptData,              "glossarist/concept_data"
  autoload :ConceptDate,              "glossarist/concept_date"
  autoload :ConceptManager,           "glossarist/concept_manager"
  autoload :ConceptSet,               "glossarist/concept_set"
  autoload :ConceptSource,            "glossarist/concept_source"
  autoload :Config,                   "glossarist/config"
  autoload :CustomLocality,           "glossarist/custom_locality"
  autoload :DetailedDefinition,       "glossarist/detailed_definition"
  autoload :Designation,              "glossarist/designation"
  autoload :Error,                    "glossarist/error"
  autoload :InvalidTypeError,         "glossarist/error/invalid_type_error"
  autoload :InvalidLanguageCodeError, "glossarist/error/invalid_language_code_error"
  autoload :ParseError,               "glossarist/error/parse_error"
  autoload :CacheVersionMismatchError, "glossarist/error/cache_version_mismatch_error"
  autoload :Locality,                 "glossarist/locality"
  autoload :LocalizedConcept,         "glossarist/localized_concept"
  autoload :ManagedConcept,           "glossarist/managed_concept"
  autoload :ManagedConceptCollection, "glossarist/managed_concept_collection"
  autoload :ManagedConceptData,       "glossarist/managed_concept_data"
  autoload :NonVerbRep,               "glossarist/non_verb_rep"
  autoload :RelatedConcept,           "glossarist/related_concept"
  autoload :Utilities,                "glossarist/utilities"
end

require_relative "glossarist/version"
require_relative "glossarist/collections"

module Glossarist
  def self.configure
    config = Glossarist::Config.instance

    yield(config) if block_given?
  end
end
