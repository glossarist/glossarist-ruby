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

  let(:gcr_path) do
    File.join(@tmpdir, "test.gcr")
  end

  before do
    @tmpdir = Dir.mktmpdir
  end

  after do
    FileUtils.rm_rf(@tmpdir)
  end

  def create_test_gcr(register: nil)
    described_class.create(
      concepts: sample_concepts,
      metadata: sample_metadata,
      register_yaml: register,
      output_path: gcr_path,
    )
    GC.start
  end

  describe ".create" do
    it "creates a valid ZIP with metadata.yaml and concepts/" do
      create_test_gcr

      expect(File.exist?(gcr_path)).to be true

      Zip::File.open(gcr_path) do |zf|
        expect(zf.find_entry("metadata.yaml")).not_to be_nil
        expect(zf.find_entry("concepts/102-01-01.yaml")).not_to be_nil
        expect(zf.find_entry("concepts/102-01-02.yaml")).not_to be_nil
      end
    end

    it "includes register.yaml when provided" do
      register = { "name" => "Test", "schema_version" => "1" }
      create_test_gcr(register: register)

      Zip::File.open(gcr_path) do |zf|
        expect(zf.find_entry("register.yaml")).not_to be_nil
        yaml = YAML.safe_load(zf.find_entry("register.yaml").get_input_stream.read)
        expect(yaml["name"]).to eq("Test")
      end
    end
  end

  describe ".load" do
    it "loads concepts from a .gcr file" do
      create_test_gcr

      package = described_class.load(gcr_path)
      expect(package.concepts.length).to eq(2)
      expect(package.concepts.map do |c|
        c["termid"]
      end).to contain_exactly("102-01-01", "102-01-02")
    end

    it "loads metadata from a .gcr file" do
      create_test_gcr

      package = described_class.load(gcr_path)
      expect(package.metadata["title"]).to eq("Test Dataset")
      expect(package.metadata["concept_count"]).to eq(2)
    end
  end

  describe "#validate" do
    it "returns valid for well-formed package" do
      create_test_gcr

      result = described_class.new(gcr_path).validate
      expect(result).to be_valid
    end

    it "returns errors for missing file" do
      result = described_class.new("/nonexistent.gcr").validate
      expect(result).not_to be_valid
      expect(result.errors).to include(a_string_matching(/File not found/))
    end
  end

  describe ".create_from_directory with reference extraction" do
    before do
      @tmpdir = Dir.mktmpdir
    end

    after do
      FileUtils.rm_rf(@tmpdir)
    end

    def create_v1_dataset
      source = File.join(@tmpdir, "source")
      concepts_dir = File.join(source, "concepts")
      FileUtils.mkdir_p(concepts_dir)

      concept = {
        "termid" => "100",
        "term" => "latitude",
        "eng" => {
          "terms" => [{ "type" => "expression", "designation" => "latitude" }],
          "definition" => [{ "content" => "See {{equality, urn:iec:std:iec:60050-102-01-01}} and {{north, 200}}" }],
        },
      }
      File.write(File.join(concepts_dir, "100.yaml"), YAML.dump(concept))
      source
    end

    it "extracts inline references during packaging" do
      source = create_v1_dataset
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
      )

      pkg = described_class.load(output)
      concept = pkg.concepts.first
      expect(concept["references"]).to be_a(Array)
      expect(concept["references"].length).to eq(2)
      ids = concept["references"].map { |r| r["concept_id"] }
      expect(ids).to contain_exactly("102-01-01", "200")
    end

    it "stores URN prefix as source for URN references" do
      source_dir = File.join(@tmpdir, "source")
      concepts_dir = File.join(source_dir, "concepts")
      FileUtils.mkdir_p(concepts_dir)

      concept = {
        "termid" => "100",
        "term" => "latitude",
        "eng" => {
          "terms" => [{ "type" => "expression", "designation" => "latitude" }],
          "definition" => [{ "content" => "See {{lat, urn:iso:std:iso:19111:ed-3:v1:en:term:3.1.32}}" }],
        },
      }
      File.write(File.join(concepts_dir, "100.yaml"), YAML.dump(concept))

      output = File.join(@tmpdir, "output.gcr")
      described_class.create_from_directory(
        source_dir,
        output: output,
        shortname: "test",
        version: "1.0.0",
      )

      pkg = described_class.load(output)
      concept = pkg.concepts.first
      expect(concept["references"]).to be_a(Array)
      ref = concept["references"].first
      expect(ref["source"]).to eq("urn:iso:std:iso:19111")
      expect(ref["concept_id"]).to eq("3.1.32")
    end

    it "includes external_references in metadata" do
      source = create_v1_dataset
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
      )

      pkg = described_class.load(output)
      ext_refs = pkg.metadata["external_references"]
      expect(ext_refs).to be_a(Array)
      uris = ext_refs.map { |r| r["uri"] }
      expect(uris).to include("urn:iec:std:iec:60050")
    end

    it "includes uri_prefix in metadata when provided" do
      source = create_v1_dataset
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
        uri_prefix: "urn:iso:std:iso:19111",
      )

      pkg = described_class.load(output)
      expect(pkg.metadata["uri_prefix"]).to eq("urn:iso:std:iso:19111")
    end
  end
end
