# frozen_string_literal: true

require "zip"
require "fileutils"

module Glossarist
  class GcrPackage
    COMPILED_EXTENSIONS = {
      "tbx" => "tbx.xml",
      "jsonld" => "jsonld",
      "turtle" => "ttl",
      "jsonl" => "jsonl",
    }.freeze

    KNOWN_COMPILED_FORMATS = COMPILED_EXTENSIONS.keys.freeze

    attr_reader :zip_path, :metadata, :concepts

    def initialize(zip_path)
      @zip_path = zip_path
      @metadata = nil
      @concepts = []
    end

    def self.create(concepts:, metadata:, output_path:, register_data: nil,
                    compiled_formats: [], **opts)
      FileUtils.mkdir_p(File.dirname(output_path))
      package = new(output_path)
      package.write(concepts, metadata, register_data,
                    compiled_formats: compiled_formats, **opts)
      package
    end

    def self.load(zip_path)
      package = new(zip_path)
      package.read
      package
    end

    def self.create_from_directory(dir, output:, shortname:, version:, # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
                                  title: nil, description: nil, owner: nil,
                                  tags: [], register_yaml: nil,
                                  uri_prefix: nil, concept_uri_template: nil,
                                  streaming: false, compiled_formats: [])
      dir = File.expand_path(dir)
      formats = Array(compiled_formats).map(&:to_s)

      if streaming && formats.any?
        raise ArgumentError,
              "Compiled formats require batch mode (streaming: true is incompatible)"
      end

      if streaming
        create_streaming(dir, output: output, shortname: shortname, version: version,
                              title: title, description: description, owner: owner,
                              tags: tags, register_yaml: register_yaml,
                              uri_prefix: uri_prefix,
                              concept_uri_template: concept_uri_template)
      else
        create_batch(dir, output: output, shortname: shortname, version: version,
                          title: title, description: description, owner: owner,
                          tags: tags, register_yaml: register_yaml,
                          uri_prefix: uri_prefix,
                          concept_uri_template: concept_uri_template,
                          compiled_formats: formats)
      end
    end

    def validate
      GcrValidator.new.validate(@zip_path)
    end

    def write(concepts, metadata, register_data, compiled_formats: [],
              shortname: nil, **opts)
      Zip::File.open(@zip_path, create: true) do |zf|
        zf.get_output_stream("metadata.yaml") do |f|
          f.write(metadata.to_yaml)
        end

        if register_data
          zf.get_output_stream("register.yaml") do |f|
            f.write(register_data.to_yaml)
          end
        end

        concepts.each do |mc|
          write_concept(zf, mc)
        end

        if compiled_formats.any?
          write_compiled(zf, concepts, compiled_formats, shortname: shortname,
                                                         **opts)
        end
      end
    end

    def write_concept(zip_file, concept)
      termid = concept.data.id.to_s
      doc = ConceptDocument.from_managed_concept(concept)
      zip_file.get_output_stream("concepts/#{termid}.yaml") do |f|
        f.write(doc.to_yamls)
      end
    end

    def read
      @concepts = []

      Zip::File.open(@zip_path) do |zf|
        if (entry = zf.find_entry("metadata.yaml"))
          @metadata = GcrMetadata.from_yaml(entry.get_input_stream.read)
        end

        zf.entries.each do |entry|
          next unless entry.name.start_with?("concepts/") && entry.name.end_with?(".yaml")

          raw = entry.get_input_stream.read
          doc = ConceptDocument.from_yamls(raw)
          @concepts << doc.to_managed_concept
        end
      end
    end

    def write_compiled(zip_file, concepts, formats, shortname: nil, **opts)
      name = shortname || "glossary"
      transform_opts = { shortname: name }.merge(opts.slice(:site_url,
                                                            :uri_prefix, :title))

      if formats.include?("tbx")
        write_compiled_tbx(zip_file, concepts, transform_opts, name)
      end

      skos_formats = formats & %w[jsonld turtle jsonl]
      if skos_formats.any?
        write_compiled_skos(zip_file, concepts, skos_formats, transform_opts,
                            name)
      end

      (formats - KNOWN_COMPILED_FORMATS).each do |fmt|
        warn "Warning: Unknown compiled format '#{fmt}', skipping"
      end
    end

    def write_compiled_tbx(zip_file, concepts, opts, name)
      require "glossarist/transforms/concept_to_tbx_transform"
      doc = Transforms::ConceptToTbxTransform.transform_document(concepts, opts)
      zip_file.get_output_stream("compiled/#{name}.tbx.xml") do |f|
        f.write(doc.to_xml)
      end
    end

    def write_compiled_skos(zip_file, concepts, formats, opts, name) # rubocop:disable Metrics/MethodLength
      require "glossarist/transforms/concept_to_skos_transform"
      vocab = Transforms::ConceptToSkosTransform.transform_document(concepts,
                                                                    opts)

      if formats.include?("jsonld")
        zip_file.get_output_stream("compiled/#{name}.jsonld") do |f|
          f.write(vocab.to_jsonld)
        end
      end

      if formats.include?("turtle")
        zip_file.get_output_stream("compiled/#{name}.ttl") do |f|
          f.write(vocab.to_turtle)
        end
      end

      return unless formats.include?("jsonl")

      zip_file.get_output_stream("compiled/#{name}.jsonl") do |f|
        concepts.each do |concept|
          skos = Transforms::ConceptToSkosTransform.transform(concept, opts)
          f.write(skos.to_jsonld)
          f.write("\n")
        end
      end
    end

    class << self
      private

      def create_batch(dir, output:, shortname:, version:,
compiled_formats: [], **opts)
        concepts = ConceptCollector.collect(dir)
        if concepts.empty?
          raise ArgumentError,
                "No concept files found in #{dir}"
        end

        enricher = ConceptEnricher.new
        enricher.inject_references(concepts)
        if opts[:concept_uri_template]
          enricher.apply_uri_template(concepts,
                                      opts[:concept_uri_template])
        end

        register_data = load_register_data(opts[:register_yaml], dir)
        metadata = build_metadata(concepts, shortname: shortname, version: version,
                                            register_data: register_data,
                                            compiled_formats: compiled_formats, **opts)

        create(
          concepts: concepts,
          metadata: metadata,
          register_data: register_data,
          output_path: File.expand_path(output),
          compiled_formats: compiled_formats,
          shortname: shortname,
          **opts,
        )
      end

      def create_streaming(dir, output:, shortname:, version:, **opts) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/BlockLength
        enricher = ConceptEnricher.new
        output_path = File.expand_path(output)
        FileUtils.mkdir_p(File.dirname(output_path))

        register_data = load_register_data(opts[:register_yaml], dir)
        concept_count = 0
        languages = Set.new

        Zip::OutputStream.open(output_path) do |zos|
          if register_data
            zos.put_next_entry("register.yaml")
            zos.write(register_data.to_yaml)
          end

          ConceptCollector.each_concept(dir) do |mc|
            enricher.inject_references([mc])
            if opts[:concept_uri_template]
              enricher.apply_uri_template([mc],
                                          opts[:concept_uri_template])
            end

            mc.localizations.each do |l10n|
              languages << l10n.language_code if l10n.language_code
            end
            concept_count += 1

            termid = mc.data.id.to_s
            doc = ConceptDocument.from_managed_concept(mc)
            zos.put_next_entry("concepts/#{termid}.yaml")
            zos.write(doc.to_yamls)
          end

          if concept_count.zero?
            raise ArgumentError,
                  "No concept files found in #{dir}"
          end

          metadata = build_streaming_metadata(concept_count, languages,
                                              shortname: shortname, version: version,
                                              register_data: register_data, **opts)
          zos.put_next_entry("metadata.yaml")
          zos.write(metadata.to_yaml)
        end

        new(output_path)
      end

      def build_streaming_metadata(concept_count, languages, shortname:, version:, # rubocop:disable Metrics/ParameterLists
                                   register_data: nil, **opts)
        GcrMetadata.new(
          shortname: shortname,
          version: version,
          title: opts[:title],
          description: opts[:description],
          owner: opts[:owner],
          tags: opts[:tags] || [],
          concept_count: concept_count,
          languages: languages.sort,
          created_at: Time.now.utc.iso8601,
          glossarist_version: Glossarist::VERSION,
          schema_version: register_data&.dig("schema_version") || SchemaMigration::CURRENT_SCHEMA_VERSION,
          uri_prefix: opts[:uri_prefix],
          concept_uri_template: opts[:concept_uri_template],
        )
      end

      def build_metadata(concepts, shortname:, version:, register_data: nil,
                         compiled_formats: [], **opts)
        GcrMetadata.from_concepts(
          concepts,
          register_data: register_data,
          options: {
            shortname: shortname,
            version: version,
            title: opts[:title],
            description: opts[:description],
            owner: opts[:owner],
            tags: opts[:tags],
            uri_prefix: opts[:uri_prefix],
            concept_uri_template: opts[:concept_uri_template],
            compiled_formats: compiled_formats,
          },
        )
      end

      def load_register_data(register_yaml_path, dir)
        path = register_yaml_path || File.join(dir, "register.yaml")
        return nil unless File.exist?(path)

        RegisterData.from_file(path)
      end
    end
  end
end
