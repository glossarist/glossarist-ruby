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

        return if v2_concepts?

        # Validate schema version (v1 only)
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

        # Validate concepts (v1 only)
        result = ConceptValidator.new(@dir).validate_all
        if result.errors.any?
          $stderr.puts "Validation errors found:"
          result.errors.each { |e| $stderr.puts "  #{e}" }
          exit 1
        end
      end

      def collect_concepts
        if v1_concepts?
          collect_v1_concepts
        elsif v2_concepts?
          collect_v2_concepts
        else
          $stderr.puts "Error: No concept files found in #{@dir}"
          exit 1
        end
      end

      def v1_concepts?
        concepts_dir = File.join(@dir, "concepts")
        File.directory?(concepts_dir) && Dir.glob(File.join(concepts_dir, "*.yaml")).any?
      end

      def v2_concepts?
        File.directory?(File.join(@dir, "geolexica-v2"))
      end

      def collect_v1_concepts
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

      def collect_v2_concepts
        collection = Glossarist::ManagedConceptCollection.new
        manager = Glossarist::ConceptManager.new(path: File.join(@dir, "geolexica-v2"))
        manager.load_from_files(collection: collection)

        collection.map { |concept| concept_to_v1_hash(concept) }
      end

      def concept_to_v1_hash(concept)
        hash = { "termid" => concept.data.id.to_s }
        concept.localizations.each do |lang, l10n|
          hash[lang] = localized_to_hash(l10n)
        end
        hash["term"] = preferred_designation(hash["eng"]&.dig("terms")) || ""
        hash
      end

      def preferred_designation(terms)
        return nil unless terms.is_a?(Array)
        primary = terms.find { |t| t.is_a?(Hash) && t["normative_status"] == "preferred" }
        primary&.dig("designation") || terms.dig(0, "designation")
      end

      def localized_to_hash(l10n)
        h = {}
        h["terms"] = l10n.designations.map(&:to_h) if l10n.designations.any?
        h["definition"] = l10n.definition.map { |d| { "content" => d.content } } if l10n.definition.any?
        h["notes"] = l10n.notes.map { |n| { "content" => n.content } } if l10n.notes.any?
        h["examples"] = l10n.examples.map { |e| { "content" => e.content } } if l10n.examples.any?
        h["sources"] = l10n.sources.map(&:to_h) if l10n.sources.any?
        h["language_code"] = l10n.language_code if l10n.language_code
        h["entry_status"] = l10n.entry_status if l10n.entry_status
        h["dates"] = l10n.dates.map(&:to_h) if l10n.dates.any?
        h
      end

      def load_register_yaml
        path = @options[:register_yaml] || File.join(@dir, "register.yaml")
        return nil unless File.exist?(path)

        YAML.safe_load_file(path, permitted_classes: [Date, Time])
      end
    end
  end
end
