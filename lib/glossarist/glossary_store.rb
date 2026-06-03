# frozen_string_literal: true

require "lutaml/store"
require "zip"

module Glossarist
  class GlossaryStore
    attr_reader :package

    def initialize
      @package = nil
      @concept_document_class = V3::ConceptDocument
    end

    # ── Load ──

    def load_directory(path, format: nil)
      metadata = load_metadata_from_directory(path)
      @concept_document_class = resolve_concept_document_class(metadata)

      definition = GcrPackageDefinition.definition(
        concept_document_class: @concept_document_class,
      )
      @package = Lutaml::Store::PackageStore.load(
        definition, path, transport: :directory, format: format
      )

      apply_metadata(metadata)
      self
    end

    def load_zip(path, format: nil)
      metadata = load_metadata_from_zip(path)
      @concept_document_class = resolve_concept_document_class(metadata)

      definition = GcrPackageDefinition.definition(
        concept_document_class: @concept_document_class,
      )
      @package = Lutaml::Store::PackageStore.load(
        definition, path, transport: :zip, format: format
      )

      apply_metadata(metadata)
      self
    end

    def load(path, format: nil)
      ext = File.extname(path).downcase
      if [".gcr", ".zip"].include?(ext)
        load_zip(path, format: format)
      else
        load_directory(path, format: format)
      end
    end

    # ── Save ──

    def save_directory(path, format: nil, formats: {})
      @package.save(path, transport: :directory, format: format,
                          formats: formats)
    end

    def save_zip(path, format: nil, formats: {})
      @package.save(path, transport: :zip, format: format, formats: formats)
    end

    # ── Concepts ──

    def concepts
      @package.models_for(@concept_document_class).map(&:to_managed_concept)
    end

    def concept(uuid)
      doc = @package.fetch_model(@concept_document_class, uuid)
      doc&.to_managed_concept
    end

    def add_concept(managed_concept)
      ensure_package
      doc = @concept_document_class.from_managed_concept(managed_concept)
      doc.id = managed_concept.uuid
      @package.add_model(doc)
    end

    def remove_concept(uuid)
      @package.remove_model(@concept_document_class, uuid)
    end

    def concept_count
      @package.model_count(@concept_document_class)
    end

    def concept_exists?(uuid)
      @package.model_exists?(@concept_document_class, uuid)
    end

    # ── Metadata ──

    def metadata
      @package&.metadata
    end

    def metadata=(value)
      ensure_package
      @package.metadata = value
    end

    # ── Register Data ──

    def register_data
      @package.models_for(RegisterData).first
    end

    def register_data=(value)
      ensure_package
      existing = register_data
      @package.remove_model(RegisterData, existing.key) if existing
      @package.add_model(value)
    end

    # ── Bibliography ──

    def bibliography
      @package.models_for(BibliographyData).first
    end

    def bibliography=(value)
      ensure_package
      existing = bibliography
      @package.remove_model(BibliographyData, existing.shortname) if existing
      @package.add_model(value)
    end

    # ── Images ──

    def image(path)
      @package.asset(path)
    end

    def add_image(path, content)
      ensure_package
      @package.add_asset(path, content)
    end

    def image_paths
      @package.asset_paths.select { |p| p.start_with?("images/") }
    end

    # ── Stats ──

    def stats
      @package&.stats
    end

    # ── Convenience ──

    def build_metadata(shortname:, version:, **opts)
      GcrMetadata.from_concepts(concepts, register_data: register_data, options: {
                                  shortname: shortname,
                                  version: version,
                                  **opts,
                                })
    end

    private

    def ensure_package
      return if @package

      definition = GcrPackageDefinition.definition(
        concept_document_class: @concept_document_class,
      )
      @package = Lutaml::Store::PackageStore.new(definition)
    end

    def resolve_concept_document_class(metadata)
      version = metadata&.schema_version.to_s
      ConceptDocument.for_version(version)
    end

    def load_metadata_from_directory(path)
      file_path = File.join(path, "metadata.yaml")
      return nil unless File.exist?(file_path)

      GcrMetadata.from_yaml(File.read(file_path, encoding: "utf-8"))
    end

    def load_metadata_from_zip(path)
      Zip::File.open(path) do |zf|
        entry = zf.find_entry("metadata.yaml")
        return nil unless entry

        GcrMetadata.from_yaml(entry.get_input_stream.read)
      end
    end

    def apply_metadata(metadata)
      @package.metadata = metadata if metadata && @package
    end
  end
end
