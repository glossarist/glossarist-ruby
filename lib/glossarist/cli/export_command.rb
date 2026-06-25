# frozen_string_literal: true

module Glossarist
  class CLI
    class ExportCommand
      AGGREGATE_FORMATS = %w[jsonld turtle tbx jsonl].freeze
      PER_CONCEPT_FORMATS = %w[json jsonld turtle yaml].freeze

      EXTENSIONS = {
        "json" => "json",
        "yaml" => "yaml",
        **GcrPackage::COMPILED_EXTENSIONS,
      }.freeze

      def initialize(path, options)
        @path = path
        @options = options
      end

      def run
        formats = parse_formats(@options[:format])
        output_dir = File.expand_path(@options[:output])
        FileUtils.mkdir_p(output_dir)

        concepts = load_concepts
        name = resolve_shortname

        formats.each do |format|
          if per_concept? && per_concept_supported?(format)
            export_per_concept(concepts, format, output_dir)
          end

          if aggregate?
            export_aggregate(format, concepts, name, output_dir)
          elsif per_concept? && !per_concept_supported?(format)
            raise ArgumentError,
                  format(
                    "Per-concept export is not supported for '%<format>s' " \
                    "(only aggregate). Drop --per-concept or pick one of: %<formats>s",
                    format: format,
                    formats: PER_CONCEPT_FORMATS.join(", "),
                  )
          end
        end

        validate_outputs!(formats, output_dir, name) if validate?
      rescue ArgumentError => e
        warn "Error: #{e.message}"
        exit 1
      end

      private

      def load_concepts
        if @path.end_with?(".gcr")
          package = GcrPackage.load(@path)
          resolve_metadata_from_package(package)
          package.concepts
        else
          GlossaryStore.new.tap { |s| s.load(@path) }.concepts
        end
      end

      def resolve_metadata_from_package(package)
        @options[:shortname] ||= package.metadata.shortname
        @options[:uri_prefix] ||= package.metadata.uri_prefix
      end

      def resolve_shortname
        @options[:shortname] || "glossary"
      end

      def transform_options
        {
          shortname: @options[:shortname],
          uri_prefix: @options[:uri_prefix],
          site_url: @options[:site_url],
          title: @options[:title],
        }.compact
      end

      def parse_formats(raw)
        Array(raw).flat_map { |value| value.to_s.split(",") }
          .map(&:strip).reject(&:empty?)
          .each { |f| validate_format!(f) }
      end

      def validate_format!(format)
        return if EXTENSIONS.key?(format)

        raise ArgumentError,
              format("Unknown format '%<format>s'. Valid formats: %<valid>s",
                     format: format,
                     valid: EXTENSIONS.keys.join(", "))
      end

      def per_concept?
        @options.fetch(:per_concept, false)
      end

      def aggregate?
        !per_concept? || @options.fetch(:aggregate, false)
      end

      def validate?
        @options.fetch(:validate, false)
      end

      def per_concept_supported?(format)
        PER_CONCEPT_FORMATS.include?(format)
      end

      def aggregate_supported?(format)
        AGGREGATE_FORMATS.include?(format) || format == "json"
      end

      def export_aggregate(format, concepts, name, output_dir)
        case format
        when "json" then export_json(concepts, output_dir)
        when "jsonld" then export_jsonld(concepts, name, output_dir)
        when "turtle" then export_turtle(concepts, name, output_dir)
        when "tbx" then export_tbx(concepts, name, output_dir)
        when "jsonl" then export_jsonl(concepts, name, output_dir)
        end
      end

      def export_json(concepts, output_dir)
        concepts.each do |concept|
          id = concept.data&.id || concept.identifier
          File.write(File.join(output_dir, "#{id}.json"), concept.to_json)
        end
      end

      def export_jsonld(concepts, name, output_dir)
        require "glossarist/transforms/concept_to_gloss_transform"
        transform = Transforms::ConceptToGlossTransform.new(nil,
                                                            transform_options)
        File.write(File.join(output_dir, "#{name}.jsonld"),
                   transform.to_jsonld(concepts))
      end

      def export_turtle(concepts, name, output_dir)
        require "glossarist/transforms/concept_to_gloss_transform"
        transform = Transforms::ConceptToGlossTransform.new(nil,
                                                            transform_options)
        File.write(File.join(output_dir, "#{name}.ttl"),
                   transform.to_turtle(concepts))
      end

      def export_tbx(concepts, name, output_dir)
        require "glossarist/transforms/concept_to_tbx_transform"
        doc = Transforms::ConceptToTbxTransform.transform_document(concepts,
                                                                   transform_options)
        File.write(File.join(output_dir, "#{name}.tbx.xml"), doc.to_xml)
      end

      def export_jsonl(concepts, name, output_dir)
        require "glossarist/transforms/concept_to_gloss_transform"
        File.open(File.join(output_dir, "#{name}.jsonl"), "w") do |f|
          concepts.each do |concept|
            transform = Transforms::ConceptToGlossTransform.new(concept,
                                                                transform_options)
            f.write(transform.to_jsonl_line)
            f.write("\n")
          end
        end
      end

      def export_per_concept(concepts, format, output_dir)
        dir = File.join(output_dir, "concepts")
        FileUtils.mkdir_p(dir)

        case format
        when "json"  then per_concept_json(concepts, dir)
        when "yaml"  then per_concept_yaml(concepts, dir)
        when "jsonld" then per_concept_jsonld(concepts, dir)
        when "turtle" then per_concept_turtle(concepts, dir)
        end
      end

      def per_concept_json(concepts, dir)
        concepts.each do |concept|
          id = concept.data&.id || concept.identifier
          File.write(File.join(dir, "#{id}.json"), concept.to_json)
        end
      end

      def per_concept_yaml(concepts, dir)
        concepts.each do |concept|
          id = concept.data&.id || concept.identifier
          File.write(File.join(dir, "#{id}.yaml"), concept.to_yaml)
        end
      end

      def per_concept_jsonld(concepts, dir)
        require "glossarist/transforms/concept_to_gloss_transform"
        concepts.each do |concept|
          id = concept.data&.id || concept.identifier
          transform = Transforms::ConceptToGlossTransform.new(concept,
                                                              transform_options)
          File.write(File.join(dir, "#{id}.jsonld"), transform.to_jsonld)
        end
      end

      def per_concept_turtle(concepts, dir)
        require "glossarist/transforms/concept_to_gloss_transform"
        concepts.each do |concept|
          id = concept.data&.id || concept.identifier
          transform = Transforms::ConceptToGlossTransform.new(concept,
                                                              transform_options)
          File.write(File.join(dir, "#{id}.ttl"), transform.to_turtle)
        end
      end

      def validate_outputs!(formats, output_dir, name)
        return unless formats.include?("turtle")

        require "glossarist/validation/shacl_validator"
        shapes_path = @options[:shapes]
        validator = Validation::ShaclValidator.new(shapes_path:)
        files = []
        files << File.join(output_dir, "#{name}.ttl") if File.exist?(File.join(output_dir, "#{name}.ttl"))
        files.concat(Dir.glob(File.join(output_dir, "concepts", "*.ttl")))
        report = validator.validate_files(files)
        unless report.conformant?
          warn report.to_s
          exit 1
        end
      end
    end
  end
end
