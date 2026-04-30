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

    def validate
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

          concept_entries = zf.entries.select { |e| e.name.start_with?("concepts/") && e.name.end_with?(".yaml") }
          if concept_entries.empty?
            result.add_error("No concept files found in concepts/")
          end

          if (entry = zf.find_entry("metadata.yaml"))
            metadata = YAML.safe_load(entry.get_input_stream.read, permitted_classes: [Date, Time])
            unless metadata.is_a?(Hash) && metadata["concept_count"]
              result.add_error("metadata.yaml missing required fields")
            end
          end
        end
      rescue => e
        result.add_error("Failed to read ZIP: #{e.message}")
      end

      result
    end

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

    def read
      @concepts = []

      Zip::File.open(@zip_path) do |zf|
        if (entry = zf.find_entry("metadata.yaml"))
          @metadata = YAML.safe_load(entry.get_input_stream.read, permitted_classes: [Date, Time], aliases: true)
        end

        zf.entries.each do |entry|
          next unless entry.name.start_with?("concepts/") && entry.name.end_with?(".yaml")

          hash = YAML.safe_load(entry.get_input_stream.read, permitted_classes: [Date, Time], aliases: true)
          @concepts << hash if hash
        end
      end
    end
  end
end
