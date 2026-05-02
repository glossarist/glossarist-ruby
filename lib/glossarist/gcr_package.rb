# frozen_string_literal: true

require "zip"
require "yaml"
require "fileutils"

module Glossarist
  class GcrPackage
    attr_reader :zip_path, :metadata, :concepts

    def initialize(zip_path)
      @zip_path = zip_path
      @metadata = nil
      @concepts = []
    end

    def self.create(concepts:, metadata:, register_yaml:, output_path:)
      FileUtils.mkdir_p(File.dirname(output_path))
      package = new(output_path)
      package.send(:write, concepts, metadata, register_yaml)
      package
    end

    def self.load(zip_path)
      package = new(zip_path)
      package.send(:read)
      package
    end

    def self.create_from_directory(dir, output:, shortname:, version:, # rubocop:disable Metrics/ParameterLists
                                  title: nil, description: nil, owner: nil,
                                  tags: [], register_yaml: nil,
                                  uri_prefix: nil)
      dir = File.expand_path(dir)
      unless File.directory?(dir)
        raise ArgumentError,
              "#{dir} is not a directory"
      end

      concepts = collect_concepts(dir)
      raise ArgumentError, "No concept files found in #{dir}" if concepts.empty?

      inject_references(concepts)

      register_data = load_register_data(register_yaml, dir)
      metadata = GcrMetadata.from_concepts(
        concepts,
        register_data: register_data,
        options: {
          shortname: shortname,
          version: version,
          title: title,
          description: description,
          owner: owner,
          tags: tags,
          uri_prefix: uri_prefix,
        },
      )

      create(
        concepts: concepts,
        metadata: metadata,
        register_yaml: register_data,
        output_path: File.expand_path(output),
      )
    end

    def validate # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      result = ValidationResult.new

      unless File.exist?(@zip_path)
        result.add_error("File not found: #{@zip_path}")
        return result
      end

      begin
        Zip::File.open(@zip_path) do |zf|
          unless zf.find_entry("metadata.yaml")
            result.add_error("Missing metadata.yaml")
          end

          concept_entries = zf.entries.select do |e|
            e.name.start_with?("concepts/") && e.name.end_with?(".yaml")
          end
          if concept_entries.empty?
            result.add_error("No concept files found in concepts/")
          end

          if (entry = zf.find_entry("metadata.yaml"))
            metadata = YAML.safe_load(entry.get_input_stream.read,
                                      permitted_classes: [Date, Time])
            unless metadata.is_a?(Hash) && metadata["concept_count"]
              result.add_error("metadata.yaml missing required fields")
            end
          end
        end
      rescue StandardError => e
        result.add_error("Failed to read ZIP: #{e.message}")
      end

      result
    end

    # Instance methods
    private

    def write(concepts, metadata, register_yaml)
      Zip::File.open(@zip_path, create: true) do |zf|
        zf.get_output_stream("metadata.yaml") do |f|
          f.write(YAML.dump(metadata.to_h))
        end

        if register_yaml
          zf.get_output_stream("register.yaml") do |f|
            f.write(YAML.dump(register_yaml))
          end
        end

        concepts.each do |concept|
          termid = concept["termid"]
          zf.get_output_stream("concepts/#{termid}.yaml") do |f|
            f.write(YAML.dump(concept))
          end
        end
      end
    end

    def read # rubocop:disable Metrics/AbcSize
      @concepts = []

      Zip::File.open(@zip_path) do |zf|
        if (entry = zf.find_entry("metadata.yaml"))
          @metadata = YAML.safe_load(entry.get_input_stream.read,
                                     permitted_classes: [Date, Time], aliases: true)
        end

        zf.entries.each do |entry|
          next unless entry.name.start_with?("concepts/") && entry.name.end_with?(".yaml")

          hash = YAML.safe_load(entry.get_input_stream.read,
                                permitted_classes: [Date, Time], aliases: true)
          @concepts << hash if hash
        end
      end
    end

    # Class methods (private)
    class << self
      private

      def collect_concepts(dir)
        if v2_concepts?(dir)
          collect_v2_concepts(dir)
        elsif v1_concepts?(dir)
          collect_v1_concepts(dir)
        else
          []
        end
      end

      def v1_concepts?(dir)
        concepts_dir = File.join(dir, "concepts")
        File.directory?(concepts_dir) && Dir.glob(File.join(concepts_dir,
                                                            "*.yaml")).any?
      end

      def v2_concepts?(dir)
        File.directory?(File.join(dir, "geolexica-v2"))
      end

      def collect_v1_concepts(dir)
        concepts_dir = File.join(dir, "concepts")
        files = Dir.glob(File.join(concepts_dir, "*.yaml"))
        concepts = []
        files.each do |file|
          hash = YAML.safe_load_file(file, permitted_classes: [Date, Time])
          concepts << hash if hash&.dig("termid")
        end
        concepts
      end

      def collect_v2_concepts(dir)
        collection = Glossarist::ManagedConceptCollection.new
        manager = Glossarist::ConceptManager.new(path: File.join(dir,
                                                                 "geolexica-v2"))
        manager.load_from_files(collection: collection)

        collection.map { |concept| concept_to_flat_hash(concept) }
      end

      def concept_to_flat_hash(concept)
        hash = { "termid" => concept.data.id.to_s }
        concept.localizations.each do |lang, l10n|
          hash[lang] = localized_to_flat_hash(l10n)
        end
        hash["term"] = preferred_designation(hash["eng"]&.dig("terms")) || ""
        hash
      end

      def localized_to_flat_hash(l10n) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        h = {}
        h["terms"] = l10n.designations.map(&:to_h) if l10n.designations.any?
        if l10n.definition.any?
          h["definition"] = l10n.definition.map do |d|
            { "content" => d.content }
          end
        end
        if l10n.notes.any?
          h["notes"] = l10n.notes.map do |n|
            { "content" => n.content }
          end
        end
        if l10n.examples.any?
          h["examples"] = l10n.examples.map do |e|
            { "content" => e.content }
          end
        end
        h["sources"] = l10n.sources.map(&:to_h) if l10n.sources.any?
        h["language_code"] = l10n.language_code if l10n.language_code
        h["entry_status"] = l10n.entry_status if l10n.entry_status
        h["dates"] = l10n.dates.map(&:to_h) if l10n.dates.any?
        if l10n.references.any?
          h["references"] = l10n.references.map do |r|
            r.respond_to?(:to_gcr_hash) ? r.to_gcr_hash : r
          end
        end
        h
      end

      def preferred_designation(terms)
        return nil unless terms.is_a?(Array)

        primary = terms.find do |t|
          t.is_a?(Hash) && t["normative_status"] == "preferred"
        end
        primary&.dig("designation") || terms.dig(0, "designation")
      end

      def load_register_data(register_yaml_path, dir)
        path = register_yaml_path || File.join(dir, "register.yaml")
        return nil unless File.exist?(path)

        YAML.safe_load_file(path, permitted_classes: [Date, Time])
      end

      def inject_references(concepts)
        extractor = ReferenceExtractor.new

        concepts.each do |concept|
          refs = extractor.extract_from_concept_hash(concept)
          next if refs.empty?

          existing = concept["references"] || []
          existing = existing.map do |r|
            r.respond_to?(:to_gcr_hash) ? r.to_gcr_hash : r
          end
          seen_keys = existing.to_set { |r| [r["source"], r["concept_id"]] }

          refs.each do |ref|
            key = [ref.source, ref.concept_id]
            next if seen_keys.include?(key)

            seen_keys.add(key)
            existing << ref.to_gcr_hash
          end
          concept["references"] = existing
        end
      end
    end
  end
end
