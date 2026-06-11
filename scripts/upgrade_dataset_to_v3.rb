#!/usr/bin/env ruby
# frozen_string_literal: true

# Upgrades a dataset directory to v3 format.
#
# Usage: bundle exec ruby scripts/upgrade_dataset_to_v3.rb <concepts_dir> [--grouped|--separate]
#
# Formats:
#   --grouped  (default): each concept + localizations in a single YAML file
#   --separate: concept/ and localized_concept/ in separate files
#
# For each concept:
#   1. Loads with ConceptManager (auto-detects v2/v3)
#   2. Promotes data.related -> top-level related (if needed)
#   3. Sets schema_version = "3"
#   4. Re-saves in v3 format

require "glossarist"

dir = ARGV[0]
mode = ARGV.include?("--separate") ? :separate : :grouped

unless dir && Dir.exist?(dir)
  abort "Usage: #{$PROGRAM_NAME} <concepts_dir> [--grouped|--separate]"
end

manager = Glossarist::ConceptManager.new(path: dir)
collection = Glossarist::ManagedConceptCollection.new

puts "Loading concepts from #{dir}..."
manager.load_from_files(collection: collection)

count = 0
collection.each do |concept|
  Glossarist::SchemaMigration::V2ToV3.migrate_concept(concept)
  count += 1
end

puts "Migrated #{count} concepts. Saving..."

if mode == :separate
  manager.save_to_files(collection)
else
  manager.save_grouped_concepts_to_files(collection)
end

puts "Done. All concepts now in v3 format."
