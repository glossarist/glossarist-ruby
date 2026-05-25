# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "securerandom"

RSpec.describe Glossarist::ConceptManager, "v2 loading" do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  def write_v2_concept(related: nil)
    concept_dir = File.join(tmpdir, "concept")
    l10n_dir = File.join(tmpdir, "localized_concept")
    FileUtils.mkdir_p(concept_dir)
    FileUtils.mkdir_p(l10n_dir)

    l10n_id = SecureRandom.uuid
    concept_id = SecureRandom.uuid

    data_hash = {
      "identifier" => "test-1",
      "localized_concepts" => { "eng" => l10n_id },
    }
    data_hash["related"] = related if related

    concept_yaml = {
      "data" => data_hash,
      "schema_version" => "2",
      "id" => concept_id,
    }.to_yaml

    l10n_yaml = {
      "data" => {
        "language_code" => "eng",
        "terms" => [{ "designation" => "test term", "type" => "expression" }],
        "definition" => [{ "content" => "test definition" }],
      },
      "id" => l10n_id,
    }.to_yaml

    File.write(File.join(concept_dir, "#{concept_id}.yaml"), concept_yaml)
    File.write(File.join(l10n_dir, "#{l10n_id}.yaml"), l10n_yaml)

    concept_id
  end

  def write_v2_concept_with_toplevel_related
    concept_dir = File.join(tmpdir, "concept")
    l10n_dir = File.join(tmpdir, "localized_concept")
    FileUtils.mkdir_p(concept_dir)
    FileUtils.mkdir_p(l10n_dir)

    l10n_id = SecureRandom.uuid
    concept_id = SecureRandom.uuid

    concept_yaml = {
      "data" => {
        "identifier" => "test-2",
        "localized_concepts" => { "eng" => l10n_id },
        "related" => [
          { "type" => "broader", "content" => "data level" },
        ],
      },
      "related" => [
        { "type" => "narrower", "content" => "top level" },
      ],
      "schema_version" => "2",
      "id" => concept_id,
    }.to_yaml

    l10n_yaml = {
      "data" => {
        "language_code" => "eng",
        "terms" => [{ "designation" => "test term", "type" => "expression" }],
        "definition" => [{ "content" => "test definition" }],
      },
      "id" => l10n_id,
    }.to_yaml

    File.write(File.join(concept_dir, "#{concept_id}.yaml"), concept_yaml)
    File.write(File.join(l10n_dir, "#{l10n_id}.yaml"), l10n_yaml)

    concept_id
  end

  describe "#load_concept_from_file" do
    it "loads v2 concepts with related inside data" do
      concept_id = write_v2_concept(related: [
                                      { "type" => "broader", "content" => "Parent concept" },
                                    ])

      manager = described_class.new(path: tmpdir)
      concepts = manager.load_concept_from_file(
        File.join(tmpdir, "concept", "#{concept_id}.yaml"),
      )

      concept = concepts.first
      expect(concept.data.related).not_to be_empty
      expect(concept.data.related.first.type).to eq("broader")
    end

    it "preserves top-level related when both exist" do
      concept_id = write_v2_concept_with_toplevel_related

      manager = described_class.new(path: tmpdir)
      concepts = manager.load_concept_from_file(
        File.join(tmpdir, "concept", "#{concept_id}.yaml"),
      )

      concept = concepts.first
      expect(concept.related.length).to eq(1)
      expect(concept.related.first.type).to eq("narrower")
    end

    it "does not set related when data.related is absent" do
      concept_id = write_v2_concept

      manager = described_class.new(path: tmpdir)
      concepts = manager.load_concept_from_file(
        File.join(tmpdir, "concept", "#{concept_id}.yaml"),
      )

      concept = concepts.first
      expect(concept.related).to be_nil.or be_empty
    end

    it "sets schema_version after detection and migration" do
      concept_id = write_v2_concept

      manager = described_class.new(path: tmpdir)
      concepts = manager.load_concept_from_file(
        File.join(tmpdir, "concept", "#{concept_id}.yaml"),
      )

      concept = concepts.first
      Glossarist::SchemaMigration.migrate_concept(concept)
      expect(concept.schema_version).to eq(Glossarist::V3_SCHEMA_VERSION)
    end

    it "migrates data.related to concept.related via SchemaMigration" do
      concept_id = write_v2_concept(related: [
                                      { "type" => "broader", "content" => "Parent" },
                                    ])

      manager = described_class.new(path: tmpdir)
      concepts = manager.load_concept_from_file(
        File.join(tmpdir, "concept", "#{concept_id}.yaml"),
      )

      concept = concepts.first
      Glossarist::SchemaMigration.migrate_concept(concept)
      expect(concept.related).not_to be_empty
      expect(concept.related.first.type).to eq("broader")
      expect(concept.data.related).to be_empty
      expect(concept.schema_version).to eq(Glossarist::V3_SCHEMA_VERSION)
    end
  end

  describe "#load_from_files" do
    it "loads all concepts with related accessible via SchemaMigration" do
      write_v2_concept(related: [
                         { "type" => "broader", "content" => "Parent1" },
                       ])
      write_v2_concept(related: [
                         { "type" => "narrower", "content" => "Child1" },
                       ])

      manager = described_class.new(path: tmpdir)
      collection = Glossarist::ManagedConceptCollection.new
      manager.load_from_files(collection: collection)

      expect(collection.count).to be >= 2

      collection.each { |c| Glossarist::SchemaMigration.migrate_concept(c) }
      related_types = collection.flat_map { |c| c.related.map(&:type) }
      expect(related_types).to include("broader", "narrower")
    end
  end
end
