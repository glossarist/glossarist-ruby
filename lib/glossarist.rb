# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

require "psych"
require "thor"
require "lutaml/model"
require "lutaml/store"

module Glossarist
  autoload :Asset,                    "glossarist/asset"
  autoload :AssetReference,           "glossarist/asset_reference"
  autoload :BibliographicReference,   "glossarist/bibliographic_reference"
  autoload :BibliographyData,         "glossarist/bibliography_data"
  autoload :BibliographyEntry,        "glossarist/bibliography_entry"
  autoload :Citation,                 "glossarist/citation"
  autoload :CLI,                      "glossarist/cli"
  autoload :CollectionConfig,         "glossarist/collection_config"
  autoload :Collection,               "glossarist/collection"
  autoload :Collections,              "glossarist/collections"
  autoload :Concept,                  "glossarist/concept"
  autoload :ConceptData,              "glossarist/concept_data"
  autoload :ConceptRef,               "glossarist/concept_ref"
  autoload :ConceptReference,         "glossarist/concept_reference"
  autoload :ReferenceExtractor,       "glossarist/reference_extractor"
  autoload :ReferenceResolver,        "glossarist/reference_resolver"
  autoload :ResolutionAdapter,        "glossarist/resolution_adapter"
  autoload :ConceptDate,              "glossarist/concept_date"
  autoload :ConceptSet,               "glossarist/concept_set"
  autoload :ConceptSource,            "glossarist/concept_source"
  autoload :ConceptStore,             "glossarist/concept_store"
  autoload :ConceptValidator,         "glossarist/concept_validator"
  autoload :ConceptComparator,        "glossarist/concept_comparator"
  autoload :ContextConfiguration,     "glossarist/context_configuration"
  autoload :ComparisonResult,         "glossarist/comparison_result"
  autoload :ConceptDiff,              "glossarist/concept_diff"
  autoload :ConceptDocument,          "glossarist/concept_document"
  autoload :ConceptEnricher, "glossarist/concept_enricher"
  autoload :Config,                   "glossarist/config"
  autoload :DatasetValidator,         "glossarist/dataset_validator"
  autoload :CustomLocality,           "glossarist/custom_locality"
  autoload :DetailedDefinition,       "glossarist/detailed_definition"
  autoload :Designation,              "glossarist/designation"
  autoload :Errors,                   "glossarist/errors"
  autoload :GcrPackage,               "glossarist/gcr_package"
  autoload :GcrPackageDefinition,     "glossarist/gcr_package_definition"
  autoload :GcrMetadata,              "glossarist/gcr_metadata"
  autoload :GcrStatistics,            "glossarist/gcr_statistics"
  autoload :GcrValidator,             "glossarist/gcr_validator"
  autoload :Locality,                 "glossarist/locality"
  autoload :LocalizedConcept,         "glossarist/localized_concept"
  autoload :ManagedConcept,           "glossarist/managed_concept"
  autoload :ManagedConceptCollection, "glossarist/managed_concept_collection"
  autoload :ManagedConceptData,       "glossarist/managed_concept_data"
  autoload :NonVerbRep,               "glossarist/non_verb_rep"
  autoload :Pronunciation,            "glossarist/pronunciation"
  autoload :RelatedConcept,           "glossarist/related_concept"
  autoload :Rdf,                      "glossarist/rdf"
  autoload :Sts,                      "glossarist/sts"
  autoload :Transforms,               "glossarist/transforms"
  autoload :SchemaMigration,          "glossarist/schema_migration"
  autoload :UrnResolver,              "glossarist/urn_resolver"
  autoload :Utilities,                "glossarist/utilities"
  autoload :Validation,               "glossarist/validation"
  autoload :RegisterData,             "glossarist/register_data"
  autoload :Section,                  "glossarist/section"
  autoload :DatasetRegister,          "glossarist/dataset_register"
  autoload :ValidationResult,         "glossarist/validation_result"
  autoload :V1,                       "glossarist/v1"
  autoload :V2,                       "glossarist/v2"
  autoload :V3,                       "glossarist/v3"
  autoload :VERSION,                  "glossarist/version"
  autoload :GlossaryDefinition,       "glossarist/glossary_definition"
  autoload :GlossaryStore,            "glossarist/glossary_store"

  LANG_CODES = %w[eng ara deu fra spa ita jpn kor pol por srp swe zho rus fin
                  dan nld msa nob nno].freeze

  SCHEMA_VERSION = "3"
  V3_SCHEMA_VERSION = "3"

  def self.configure
    config = Glossarist::Config.instance

    yield(config) if block_given?
  end
end
