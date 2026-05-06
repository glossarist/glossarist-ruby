# frozen_string_literal: true

module Glossarist
  class CLI
    class ExportCommand
      EXTENSIONS = {
        "json" => "json",
        **GcrPackage::COMPILED_EXTENSIONS,
      }.freeze

      def initialize(path, options)
        @path = path
        @options = options
      end

      def run
        format = @options[:format]
        output_dir = File.expand_path(@options[:output])
        FileUtils.mkdir_p(output_dir)

        concepts = load_concepts
        name = resolve_shortname

        case format
        when "json" then export_json(concepts, output_dir)
        when "jsonld" then export_jsonld(concepts, name, output_dir)
        when "turtle" then export_turtle(concepts, name, output_dir)
        when "tbx" then export_tbx(concepts, name, output_dir)
        when "jsonl" then export_jsonl(concepts, name, output_dir)
        end
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
          collection = ManagedConceptCollection.new
          collection.load_from_files(@path)
          collection.to_a
        end
      end

      def resolve_metadata_from_package(package)
        @options[:shortname] ||= package.metadata["shortname"]
        @options[:uri_prefix] ||= package.metadata["uri_prefix"]
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

      def export_json(concepts, output_dir)
        concepts.each do |concept|
          id = concept.data&.id || concept.identifier
          File.write(File.join(output_dir, "#{id}.json"), concept.to_json)
        end
      end

      def export_jsonld(concepts, name, output_dir)
        require "glossarist/transforms/concept_to_skos_transform"
        vocab = Transforms::ConceptToSkosTransform.transform_document(concepts,
                                                                      transform_options)
        File.write(File.join(output_dir, "#{name}.jsonld"), vocab.to_jsonld)
      end

      def export_turtle(concepts, name, output_dir)
        require "glossarist/transforms/concept_to_skos_transform"
        vocab = Transforms::ConceptToSkosTransform.transform_document(concepts,
                                                                      transform_options)
        File.write(File.join(output_dir, "#{name}.ttl"), vocab.to_turtle)
      end

      def export_tbx(concepts, name, output_dir)
        require "glossarist/transforms/concept_to_tbx_transform"
        doc = Transforms::ConceptToTbxTransform.transform_document(concepts,
                                                                   transform_options)
        File.write(File.join(output_dir, "#{name}.tbx.xml"), doc.to_xml)
      end

      def export_jsonl(concepts, name, output_dir)
        require "glossarist/transforms/concept_to_skos_transform"
        File.open(File.join(output_dir, "#{name}.jsonl"), "w") do |f|
          concepts.each do |concept|
            skos = Transforms::ConceptToSkosTransform.transform(concept,
                                                                transform_options)
            f.write(skos.to_jsonld)
            f.write("\n")
          end
        end
      end
    end
  end
end
