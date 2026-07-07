# frozen_string_literal: true

require "fileutils"

module Glossarist
  class SchemaMigration
    # Orchestrator for the `glossarist upgrade` CLI command.
    #
    # Reads source concepts from a directory, dispatches each file to the
    # right migrator (V0ToV1 for IEV-legacy hashes, V2ToV3 for model-level
    # version bumps), reads register.yaml, and writes the output either as
    # a directory of YAML files or as a `.gcr` ZIP package.
    #
    # This is the third concern that previously lived tangled in
    # SchemaMigration itself (alongside V0ToV1 and V2ToV3). Splitting it
    # out keeps each module at a single abstraction level:
    #   - V0ToV1: hash → hash transform
    #   - V2ToV3: model → model transform
    #   - CliPipeline (this file): file I/O + dispatch + output writing
    class CliPipeline
      attr_reader :source_dir, :output, :target_version, :cross_references,
                  :dry_run

      def initialize(source_dir, output:, target_version:,
                     cross_references: nil, dry_run: false)
        @source_dir = File.expand_path(source_dir)
        @output = output
        @target_version = target_version
        @cross_references = cross_references
        @dry_run = dry_run
      end

      def run
        validate_source!
        concepts = read_and_migrate_concepts
        register_data = read_register_yaml
        write_output(concepts, register_data)

        {
          concepts: concepts,
          register_data: register_data,
          source_version: source_version,
          target_version: target_version,
          output: File.expand_path(output),
          count: concepts.length,
        }
      end

      private

      def validate_source!
        unless File.directory?(source_dir)
          raise ArgumentError, "#{source_dir} is not a directory"
        end
        return if concepts_dir

        raise ArgumentError, "No concept YAML files found in #{source_dir}"
      end

      def concepts_dir
        @concepts_dir ||= [
          File.join(source_dir, "concepts"),
          source_dir,
        ].find { |dir| Dir.glob(File.join(dir, "*.yaml")).any? }
      end

      def source_version
        @source_version ||= begin
          register = V1::Register.from_file(File.join(source_dir,
                                                      "register.yaml"))
          register&.schema_version || "0"
        end
      end

      def ref_maps
        @ref_maps ||= begin
          xref = V1::CrossReferences.from_file(cross_references)
          xref ? xref.to_ref_maps : {}
        end
      end

      def read_and_migrate_concepts
        files = Dir.glob(File.join(concepts_dir, "*.yaml"))
        concepts = []
        errors = 0

        files.each do |file|
          v1 = V1::Concept.from_file(file)
          next unless v1

          migration = V0ToV1.new(
            v1.to_yaml_hash,
            from_version: source_version,
            to_version: target_version,
            ref_maps: ref_maps,
          )
          concepts << migration.migrate
        rescue Errors::Base, Psych::SyntaxError => e
          errors += 1
          warn "  Error migrating #{File.basename(file)}: #{e.message}" if errors <= 5
        end

        warn "  ... #{errors - 5} more errors" if errors > 5
        concepts
      end

      def read_register_yaml
        register = V1::Register.from_file(File.join(source_dir,
                                                    "register.yaml"))
        return nil unless register

        data = register.to_h
        data["schema_version"] = target_version
        data
      end

      def write_output(concepts, register_data)
        output_path = File.expand_path(output)

        if File.extname(output).downcase == ".gcr"
          write_gcr(concepts, register_data, output_path)
        else
          write_directory(concepts, register_data, output_path)
        end
      end

      def write_gcr(concepts, register_data, output_path)
        if dry_run
          puts "Would package #{concepts.length} concepts into #{output_path}"
          return
        end

        v1_concepts = concepts.map { |h| V1::Concept.of_yaml(h).to_managed_concept }
        rd = register_data ? RegisterData.of_yaml(register_data) : nil
        metadata = GcrMetadata.from_concepts(v1_concepts, register_data: rd)
        GcrPackage.create(
          concepts: v1_concepts,
          metadata: metadata,
          register_data: rd,
          output_path: output_path,
        )
      end

      def write_directory(concepts, register_data, output_path)
        if dry_run
          puts "Would write #{concepts.length} concepts to #{File.join(
            output_path, 'concepts/'
          )}"
          return
        end

        concepts_out = File.join(output_path, "concepts")
        FileUtils.mkdir_p(concepts_out)

        concepts.each do |concept|
          termid = concept["termid"]
          mc = V1::Concept.of_yaml(concept).to_managed_concept
          File.write(File.join(concepts_out, "#{termid}.yaml"), mc.to_yaml)
        end

        return unless register_data

        rd = RegisterData.of_yaml(register_data)
        File.write(File.join(output_path, "register.yaml"), rd.to_yaml)
      end
    end
  end
end
