# frozen_string_literal: true

require "lutaml/store"

module Glossarist
  module GcrPackageDefinition
    def self.definition(concept_document_class: V3::ConceptDocument)
      Lutaml::Store::PackageDefinition.new(
        name: :gcr,
        metadata_model: GcrMetadata,
        metadata_file: "metadata.yaml",
      ) do |pkg|
        pkg.model(
          model: concept_document_class,
          dir: "concepts",
          layout: :grouped,
          key: :id,
          default_format: :yamls,
          serializer: ConceptStore::ConceptDocumentSerializer.new,
        )
        pkg.model(
          model: RegisterData,
          file: "register.yaml",
          key: :key,
          default_format: :yaml,
        )
        pkg.model(
          model: BibliographyData,
          file: "bibliography.yaml",
          key: :shortname,
          default_format: :yaml,
        )
        pkg.asset("images", type: :directory)
      end
    end
  end
end
