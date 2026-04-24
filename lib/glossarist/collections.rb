# frozen_string_literal: true

module Glossarist
  module Collections
    autoload :AssetCollection,               "glossarist/collections/asset_collection"
    autoload :BibliographyCollection,        "glossarist/collections/bibliography_collection"
    autoload :Collection,                    "glossarist/collections/collection"
    autoload :ConceptSourceCollection,       "glossarist/collections/concept_source_collection"
    autoload :DesignationCollection,         "glossarist/collections/designation_collection"
    autoload :DetailedDefinitionCollection,  "glossarist/collections/detailed_definition_collection"
    autoload :LocalizationCollection,        "glossarist/collections/localization_collection"
    autoload :TypedCollection,               "glossarist/collections/typed_collection"
  end
end
