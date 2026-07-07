# frozen_string_literal: true

# Facade for schema migration. Each abstraction level lives in its own
# module under SchemaMigration:: — the facade preserves the historical
# class-method API so existing callers (CLI upgrade command, V2/V3
# namespace specs, downstream gems) don't break.
#
# Architecture (MECE):
#   - V0ToV1: hash to hash transform (IEV legacy YAML to V1 shape).
#   - V2ToV3: model to model transform (V2::ManagedConcept to V3::ManagedConcept).
#   - CliPipeline: file I/O + dispatch + output writing for the
#     `glossarist upgrade` CLI command.
#
# Each module has a single public entry point (V0ToV1#migrate,
# V2ToV3.migrate_concept, CliPipeline#run) and is independently testable.
# Adding V3ToV4 later = adding a new module, not editing these.
module Glossarist
  class SchemaMigration
    CURRENT_SCHEMA_VERSION = "1"

    autoload :V0ToV1,      "glossarist/schema_migration/v0_to_v1"
    autoload :V2ToV3,      "glossarist/schema_migration/v2_to_v3"
    autoload :CliPipeline, "glossarist/schema_migration/cli_pipeline"

    # Convenience: `SchemaMigration.new(input, **opts)` is shorthand for
    # `V0ToV1.new(input, **opts)`. Preserved for backward compatibility.
    def self.new(...)
      V0ToV1.new(...)
    end

    def self.migrate_concept(concept, target_version: Glossarist::SCHEMA_VERSION)
      V2ToV3.migrate_concept(concept, target_version: target_version)
    end

    def self.concept_version(concept)
      V2ToV3.concept_version(concept)
    end

    def self.upgrade_directory(source_dir, output:, target_version: CURRENT_SCHEMA_VERSION,
                               cross_references: nil, dry_run: false)
      CliPipeline.new(
        source_dir,
        output: output,
        target_version: target_version,
        cross_references: cross_references,
        dry_run: dry_run,
      ).run
    end
  end
end
