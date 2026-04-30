# frozen_string_literal: true

require "yaml"
require "fileutils"

module Glossarist
  class CLI
    class UpgradeCommand
      def initialize(source_dir, options)
        @source_dir = File.expand_path(source_dir)
        @output = options[:output]
        @target_version = options[:target_version] || SchemaMigration::CURRENT_SCHEMA_VERSION
        @cross_references_path = options[:cross_references]
        @dry_run = options[:dry_run]
      end

      def run
        validate_source
        detect_schema_version
        load_ref_maps

        concepts = read_and_migrate_concepts
        register_data = read_register_yaml

        output_gcr? ? write_gcr(concepts, register_data) : write_directory(concepts, register_data)

        report(concepts.length)
      end

      private

      def validate_source
        unless File.directory?(@source_dir)
          $stderr.puts "Error: #{@source_dir} is not a directory"
          exit 1
        end

        @concepts_dir = find_concepts_dir
        unless @concepts_dir && Dir.glob(File.join(@concepts_dir, "*.yaml")).any?
          $stderr.puts "Error: No concept YAML files found in #{@source_dir}"
          exit 1
        end
      end

      def find_concepts_dir
        candidates = [
          File.join(@source_dir, "concepts"),
          @source_dir,
        ]
        candidates.find { |dir| Dir.glob(File.join(dir, "*.yaml")).any? }
      end

      def detect_schema_version
        register_path = File.join(@source_dir, "register.yaml")
        if File.exist?(register_path)
          register = YAML.safe_load_file(register_path, permitted_classes: [Date, Time])
          @source_version = register&.dig("schema_version")&.to_s || "0"
        else
          @source_version = "0"
        end
        puts "Source schema version: #{@source_version}" unless @dry_run
      end

      def load_ref_maps
        @ref_maps = {}
        return unless @cross_references_path && File.exist?(@cross_references_path)

        config = YAML.safe_load_file(@cross_references_path, permitted_classes: [Date, Time])
        xref = config["crossReferences"] || {}
        @ref_maps = {
          ref_prefix_map: xref["refPrefixMap"] || {},
          urn_standard_map: xref["urnStandardMap"] || {},
        }
      end

      def read_and_migrate_concepts
        files = Dir.glob(File.join(@concepts_dir, "*.yaml"))
        concepts = []
        errors = 0

        files.each do |file|
          begin
            hash = YAML.safe_load_file(file, permitted_classes: [Date, Time])
            next unless hash&.dig("termid")

            migration = SchemaMigration.new(
              hash,
              from_version: @source_version,
              to_version: @target_version,
              ref_maps: @ref_maps,
            )
            migrated = migration.migrate
            concepts << migrated
          rescue => e
            errors += 1
            $stderr.puts "  Error migrating #{File.basename(file)}: #{e.message}" if errors <= 5
          end
        end

        $stderr.puts "  ... #{errors - 5} more errors" if errors > 5
        puts "  Migrated #{concepts.length} concepts (#{errors} errors)" unless @dry_run
        concepts
      end

      def read_register_yaml
        register_path = File.join(@source_dir, "register.yaml")
        return nil unless File.exist?(register_path)

        data = YAML.safe_load_file(register_path, permitted_classes: [Date, Time]) || {}
        data["schema_version"] = @target_version
        data
      end

      def output_gcr?
        File.extname(@output).downcase == ".gcr"
      end

      def write_directory(concepts, register_data)
        out_dir = File.expand_path(@output)
        concepts_out = File.join(out_dir, "concepts")

        if @dry_run
          puts "Would write #{concepts.length} concepts to #{concepts_out}/"
          return
        end

        FileUtils.mkdir_p(concepts_out)

        concepts.each do |concept|
          termid = concept["termid"]
          File.write(File.join(concepts_out, "#{termid}.yaml"), YAML.dump(concept))
        end

        if register_data
          File.write(File.join(out_dir, "register.yaml"), YAML.dump(register_data))
        end
      end

      def write_gcr(concepts, register_data)
        require "glossarist/gcr_package"
        require "glossarist/gcr_metadata"

        if @dry_run
          puts "Would package #{concepts.length} concepts into #{@output}"
          return
        end

        metadata = GcrMetadata.from_concepts(concepts, register_data: register_data)
        GcrPackage.create(
          concepts: concepts,
          metadata: metadata,
          register_yaml: register_data,
          output_path: File.expand_path(@output),
        )
      end

      def report(count)
        puts "Upgraded #{count} concepts from schema v#{@source_version} to v#{@target_version}"
        puts "Output: #{@output}"
      end
    end
  end
end
