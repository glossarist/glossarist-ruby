# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Glossarist::GcrPackage do
  let(:sample_concepts) do
    [
      {
        "termid" => "102-01-01",
        "term" => "equality",
        "eng" => {
          "terms" => [{ "type" => "expression", "designation" => "equality" }],
          "definition" => [{ "content" => "test definition" }],
          "entry_status" => "valid",
        },
      },
      {
        "termid" => "102-01-02",
        "term" => "quantity",
        "eng" => {
          "terms" => [{ "type" => "expression", "designation" => "quantity" }],
          "definition" => [{ "content" => "another definition" }],
          "entry_status" => "valid",
        },
      },
    ]
  end

  let(:sample_metadata) do
    Glossarist::GcrMetadata.new(
      title: "Test Dataset",
      concept_count: 2,
      languages: ["eng"],
      created_at: "2026-04-28T12:00:00+00:00",
      glossarist_version: Glossarist::VERSION,
      schema_version: "1",
      statistics: Glossarist::GcrStatistics.from_concepts(sample_concepts),
    )
  end

  describe ".create" do
    it "creates a valid ZIP with metadata.yaml and concepts/" do
      Dir.mktmpdir do |dir|
        output = File.join(dir, "test.gcr")

        package = described_class.create(
          concepts: sample_concepts,
          metadata: sample_metadata,
          register_yaml: nil,
          output_path: output,
        )

        expect(File.exist?(output)).to be true

        Zip::File.open(output) do |zf|
          expect(zf.find_entry("metadata.yaml")).not_to be_nil
          expect(zf.find_entry("concepts/102-01-01.yaml")).not_to be_nil
          expect(zf.find_entry("concepts/102-01-02.yaml")).not_to be_nil
        end
      end
    end

    it "includes register.yaml when provided" do
      Dir.mktmpdir do |dir|
        output = File.join(dir, "test.gcr")
        register = { "name" => "Test", "schema_version" => "1" }

        described_class.create(
          concepts: sample_concepts,
          metadata: sample_metadata,
          register_yaml: register,
          output_path: output,
        )

        Zip::File.open(output) do |zf|
          expect(zf.find_entry("register.yaml")).not_to be_nil
          yaml = YAML.safe_load(zf.find_entry("register.yaml").get_input_stream.read)
          expect(yaml["name"]).to eq("Test")
        end
      end
    end
  end

  describe ".load" do
    it "loads concepts from a .gcr file" do
      Dir.mktmpdir do |dir|
        output = File.join(dir, "test.gcr")

        described_class.create(
          concepts: sample_concepts,
          metadata: sample_metadata,
          register_yaml: nil,
          output_path: output,
        )

        package = described_class.load(output)
        expect(package.concepts.length).to eq(2)
        expect(package.concepts.map { |c| c["termid"] }).to contain_exactly("102-01-01", "102-01-02")
      end
    end

    it "loads metadata from a .gcr file" do
      Dir.mktmpdir do |dir|
        output = File.join(dir, "test.gcr")

        described_class.create(
          concepts: sample_concepts,
          metadata: sample_metadata,
          register_yaml: nil,
          output_path: output,
        )

        package = described_class.load(output)
        expect(package.metadata["title"]).to eq("Test Dataset")
        expect(package.metadata["concept_count"]).to eq(2)
      end
    end
  end

  describe "#validate" do
    it "returns valid for well-formed package" do
      Dir.mktmpdir do |dir|
        output = File.join(dir, "test.gcr")

        described_class.create(
          concepts: sample_concepts,
          metadata: sample_metadata,
          register_yaml: nil,
          output_path: output,
        )

        result = described_class.new(output).validate
        expect(result).to be_valid
      end
    end

    it "returns errors for missing file" do
      result = described_class.new("/nonexistent.gcr").validate
      expect(result).not_to be_valid
      expect(result.errors).to include(a_string_matching(/File not found/))
    end
  end
end
