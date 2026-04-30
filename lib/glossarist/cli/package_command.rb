# frozen_string_literal: true

require "yaml"
require "fileutils"

module Glossarist
  class CLI
    class PackageCommand
      def initialize(dir, options)
        @dir = File.expand_path(dir)
        @output = options[:output]
        @options = options
      end

      def run
        validate_input
        concepts = collect_concepts
        register_data = load_register_yaml
        metadata = GcrMetadata.from_concepts(concepts, register_data: register_data, options: @options)

        GcrPackage.create(
          concepts: concepts,
          metadata: metadata,
          register_yaml: register_data,
          output_path: File.expand_path(@output),
        )

        puts "Created #{@output} with #{concepts.length} concepts"
      end

      private

      def validate_input
        unless File.directory?(@dir)
          $stderr.puts "Error: #{@dir} is not a directory"
          exit 1
        end

        # Validate schema version
        register_path = File.join(@dir, "register.yaml")
        if File.exist?(register_path)
          register = YAML.safe_load_file(register_path, permitted_classes: [Date, Time])
          version = register&.dig("schema_version")&.to_s || "0"
          if version != SchemaMigration::CURRENT_SCHEMA_VERSION
            $stderr.puts "Error: Dataset is schema v#{version}, expected v#{SchemaMigration::CURRENT_SCHEMA_VERSION}"
            $stderr.puts "Run 'glossarist upgrade #{@dir} -o <upgraded_dir>' first"
            exit 1
          end
        else
          $stderr.puts "Warning: No register.yaml found, proceeding without schema version check"
        end

        # Validate concepts
        result = ConceptValidator.new(@dir).validate_all
        if result.errors.any?
          $stderr.puts "Validation errors found:"
          result.errors.each { |e| $stderr.puts "  #{e}" }
          exit 1
        end
      end

      def collect_concepts
        concepts_dir = File.directory?(File.join(@dir, "concepts")) \
          ? File.join(@dir, "concepts") \
          : @dir

        files = Dir.glob(File.join(concepts_dir, "*.yaml"))
        concepts = []
        files.each do |file|
          hash = YAML.safe_load_file(file, permitted_classes: [Date, Time])
          concepts << hash if hash&.dig("termid")
        end
        concepts
      end

      def load_register_yaml
        path = @options[:register_yaml] || File.join(@dir, "register.yaml")
        return nil unless File.exist?(path)

        YAML.safe_load_file(path, permitted_classes: [Date, Time])
      end
    end
  end
end
