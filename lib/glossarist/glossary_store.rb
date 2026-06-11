# frozen_string_literal: true

module Glossarist
  class GlossaryStore
    attr_reader :package, :localized_concepts_dir_name

    def initialize
      @package = nil
      @concept_document_class = V3::ConceptDocument
      @v1_concepts = nil
      @localized_concepts_dir_name = nil
    end

    # ── Load ──

    def load_directory(path, format: nil)
      if v1_dataset?(path)
        load_v1_fallback(path)
        return self
      end

      if legacy_managed_layout?(path)
        load_legacy_managed(path)
        return self
      end

      if grouped_at_root?(path)
        load_grouped_at_root(path)
        return self
      end

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
      return @v1_concepts if @v1_concepts

      @package.models_for(@concept_document_class).map(&:to_managed_concept)
    end

    def each_concept(&block)
      return enum_for(:each_concept) unless block

      if @v1_concepts
        @v1_concepts.each(&block)
      else
        @package.models_for(@concept_document_class).each do |doc|
          yield doc.to_managed_concept
        end
      end
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

    def load_v1_fallback(path)
      concepts_dir = File.join(path, "concepts")
      files = Dir.glob(File.join(concepts_dir, "*.yaml"))
      @v1_concepts = files.filter_map do |file|
        v1 = V1::Concept.from_file(file)
        v1&.to_managed_concept
      end
    end

    def legacy_managed_layout?(path)
      concept_dir = File.join(path, "concept")
      return false unless File.directory?(concept_dir)
      return false if File.directory?(File.join(path, "concepts"))

      Dir.glob(File.join(concept_dir, "*.yaml")).any?
    end

    def load_legacy_managed(path)
      concept_dir = File.join(path, "concept")
      lc_dir = find_localized_concepts_dir(path)
      lc_index = build_lc_index(lc_dir) if lc_dir

      @v1_concepts = []
      Dir.glob(File.join(concept_dir, "*.yaml")).each do |f|
        raw = File.read(f, encoding: "utf-8")
        version = detect_version(raw)
        doc_class = ConceptDocument.for_version(version)
        doc = doc_class.from_yamls(raw)
        mc = doc.concept
        next unless mc&.data&.id

        mc.uuid = mc.identifier || mc.data.id
        load_legacy_localizations(mc, lc_index, version) if lc_index
        @v1_concepts << mc
      rescue Psych::SyntaxError => e
        raise Errors::ParseError.new(filename: f, line: e.line)
      rescue Lutaml::Model::InvalidFormatError => e
        raise Errors::ParseError.new(filename: f, message: e.message)
      rescue Encoding::InvalidByteSequenceError => e
        raise Errors::LoadError.new(path: f, reason: e.message)
      end
    end

    def load_legacy_localizations(managed_concept, lc_index, version = "3")
      l10n_class = version.to_s == "2" ? V2::LocalizedConcept : LocalizedConcept
      lc_map = managed_concept.data.localized_concepts || {}
      lc_map.each_value do |uuid|
        lc_file = lc_index[uuid]
        unless lc_file
          raise Errors::LoadError.new(path: lc_file,
                                      reason: "Referenced localization #{uuid} not found")
        end

        l10n = l10n_class.from_yaml(File.read(lc_file, encoding: "utf-8"))
        l10n.uuid = uuid
        managed_concept.add_localization(l10n)
      rescue Errors::LoadError
        raise
      rescue Psych::SyntaxError => e
        raise Errors::ParseError.new(filename: lc_file, line: e.line)
      rescue Errno::ENOENT
        raise Errors::LoadError.new(path: lc_file, reason: "File not found")
      rescue Errno::EACCES
        raise Errors::LoadError.new(path: lc_file, reason: "Permission denied")
      end
    end

    def find_localized_concepts_dir(path)
      %w[localized_concept localized-concept].each do |name|
        d = File.join(path, name)
        if File.directory?(d)
          @localized_concepts_dir_name = name
          return d
        end
      end
      nil
    end

    def build_lc_index(lc_dir)
      Dir.glob(File.join(lc_dir, "*.{yaml,yml}"))
        .to_h { |f| [File.basename(f, ".*"), f] }
    end

    def grouped_at_root?(path)
      return false if File.directory?(File.join(path, "concepts"))
      return false if File.directory?(File.join(path, "concept"))

      Dir.glob(File.join(path, "*.yaml")).any? do |f|
        raw = File.read(f, encoding: "utf-8")
        hash = YAML.safe_load(raw, permitted_classes: [Date, Time])
        hash.is_a?(Hash) && hash.key?("data") && hash["data"].is_a?(Hash) &&
          hash["data"].key?("identifier")
      rescue Psych::SyntaxError, Encoding::InvalidByteSequenceError
        false
      end
    end

    def load_grouped_at_root(path)
      @v1_concepts = []
      Dir.glob(File.join(path, "*.yaml")).each do |f|
        raw = File.read(f, encoding: "utf-8")
        version = detect_version(raw)
        doc_class = ConceptDocument.for_version(version)
        doc = doc_class.from_yamls(raw)
        mc = doc.concept
        next unless mc&.data&.id

        mc.uuid = mc.identifier || mc.data.id
        Array(doc.localizations).each { |l10n| mc.add_localization(l10n) }
        @v1_concepts << mc
      rescue Psych::SyntaxError => e
        raise Errors::ParseError.new(filename: f, line: e.line)
      rescue Lutaml::Model::InvalidFormatError => e
        raise Errors::ParseError.new(filename: f, message: e.message)
      rescue Encoding::InvalidByteSequenceError => e
        raise Errors::LoadError.new(path: f, reason: e.message)
      end
    end

    def detect_version(raw)
      if (m = raw.match(/^schema_version:\s*v?(\d)/))
        m[1]
      else
        "2"
      end
    end

    def v1_dataset?(path)
      concepts_dir = File.join(path, "concepts")
      return false unless File.directory?(concepts_dir)

      metadata_file = File.join(path, "metadata.yaml")
      concept_subdir = File.join(concepts_dir, "concept")
      return false if File.exist?(metadata_file) || File.directory?(concept_subdir)

      sample = Dir.glob(File.join(concepts_dir, "*.yaml")).first
      return false unless sample

      raw = File.read(sample, encoding: "utf-8")
      hash = YAML.safe_load(raw, permitted_classes: [Date, Time])
      hash.is_a?(Hash) && hash.key?("termid")
    rescue Psych::SyntaxError, Encoding::InvalidByteSequenceError
      false
    end
  end
end
