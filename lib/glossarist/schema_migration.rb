# frozen_string_literal: true

require "fileutils"

module Glossarist
  class SchemaMigration
    CURRENT_SCHEMA_VERSION = "1"

    autoload :V0ToV1, "glossarist/schema_migration/v0_to_v1"
    autoload :V2ToV3, "glossarist/schema_migration/v2_to_v3"

    def self.new(...)
      V0ToV1.new(...)
    end

    def self.migrate_concept(concept, target_version: Glossarist::SCHEMA_VERSION)
      V2ToV3.migrate_concept(concept, target_version: target_version)
    end

    def self.concept_version(concept)
      V2ToV3.concept_version(concept)
    end

    def self.upgrade_directory(source_dir, output:, # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
                              target_version: CURRENT_SCHEMA_VERSION,
                              cross_references: nil,
                              dry_run: false)
      source_dir = File.expand_path(source_dir)

      concepts_dir = find_concepts_dir(source_dir)
      unless File.directory?(source_dir)
        raise ArgumentError,
              "#{source_dir} is not a directory"
      end
      unless concepts_dir
        raise ArgumentError,
              "No concept YAML files found in #{source_dir}"
      end

      source_version = detect_schema_version(source_dir)
      ref_maps = load_ref_maps(cross_references)
      concepts = read_and_migrate_concepts(concepts_dir, source_version,
                                           target_version, ref_maps)
      register_data = read_register_yaml(source_dir, target_version)

      write_output(concepts, register_data, output, dry_run)

      {
        concepts: concepts,
        register_data: register_data,
        source_version: source_version,
        target_version: target_version,
        output: File.expand_path(output),
        count: concepts.length,
      }
    end

    class << self
      private

      def find_concepts_dir(source_dir)
        candidates = [
          File.join(source_dir, "concepts"),
          source_dir,
        ]
        candidates.find { |dir| Dir.glob(File.join(dir, "*.yaml")).any? }
      end

      def detect_schema_version(source_dir)
        register = V1::Register.from_file(File.join(source_dir,
                                                    "register.yaml"))
        register&.schema_version || "0"
      end

      def load_ref_maps(cross_references_path)
        xref = V1::CrossReferences.from_file(cross_references_path)
        xref ? xref.to_ref_maps : {}
      end

      def read_and_migrate_concepts(concepts_dir, source_version, # rubocop:disable Metrics/MethodLength
                                    target_version, ref_maps)
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

      def read_register_yaml(source_dir, target_version)
        register = V1::Register.from_file(File.join(source_dir,
                                                    "register.yaml"))
        return nil unless register

        data = register.to_h
        data["schema_version"] = target_version
        data
      end

      def write_output(concepts, register_data, output, dry_run) # rubocop:disable Metrics/MethodLength
        output_path = File.expand_path(output)

        if File.extname(output).downcase == ".gcr"
          if dry_run
            puts "Would package #{concepts.length} concepts into #{output_path}"
            return
          end

          v1_concepts = concepts.map { |h| V1::Concept.of_yaml(h).to_managed_concept }
          rd = register_data ? RegisterData.of_yaml(register_data) : nil
          metadata = GcrMetadata.from_concepts(v1_concepts,
                                               register_data: rd)
          GcrPackage.create(
            concepts: v1_concepts,
            metadata: metadata,
            register_data: rd,
            output_path: output_path,
          )
        else
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
            File.write(File.join(concepts_out, "#{termid}.yaml"),
                       mc.to_yaml)
          end

          if register_data
            rd = RegisterData.of_yaml(register_data)
            File.write(File.join(output_path, "register.yaml"),
                       rd.to_yaml)
          end
        end
      end
    end
  end
end
