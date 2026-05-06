# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "glossarist/cli/export_command"

RSpec.describe Glossarist::CLI::ExportCommand do
  let(:fixtures_dir) { fixtures_path("concept_collection_v2") }

  before { @tmpdir = Dir.mktmpdir }
  after { FileUtils.rm_rf(@tmpdir) }

  describe "JSON export" do
    it "writes per-concept JSON files" do
      cmd = described_class.new(fixtures_dir,
                                format: "json", output: @tmpdir)
      cmd.run

      json_files = Dir.glob(File.join(@tmpdir, "*.json"))
      expect(json_files.length).to be >= 1
    end
  end

  describe "JSON-LD export" do
    it "writes a single JSON-LD file with @graph" do
      cmd = described_class.new(fixtures_dir,
                                format: "jsonld", output: @tmpdir,
                                shortname: "test")
      cmd.run

      output = File.join(@tmpdir, "test.jsonld")
      expect(File.exist?(output)).to be true
      parsed = JSON.parse(File.read(output))
      expect(parsed["@graph"]).to be_an(Array)
    end
  end

  describe "Turtle export" do
    it "writes a single Turtle file" do
      cmd = described_class.new(fixtures_dir,
                                format: "turtle", output: @tmpdir,
                                shortname: "test")
      cmd.run

      output = File.join(@tmpdir, "test.ttl")
      expect(File.exist?(output)).to be true
      content = File.read(output)
      expect(content).to include("@prefix skos:")
    end
  end

  describe "TBX export" do
    it "writes a single TBX-XML file" do
      cmd = described_class.new(fixtures_dir,
                                format: "tbx", output: @tmpdir,
                                shortname: "test")
      cmd.run

      output = File.join(@tmpdir, "test.tbx.xml")
      expect(File.exist?(output)).to be true
      content = File.read(output)
      expect(content).to include("<tbx")
    end
  end

  describe "JSONL export" do
    it "writes a JSONL file with one JSON object per line" do
      cmd = described_class.new(fixtures_dir,
                                format: "jsonl", output: @tmpdir,
                                shortname: "test")
      cmd.run

      output = File.join(@tmpdir, "test.jsonl")
      expect(File.exist?(output)).to be true
      lines = File.read(output).strip.split("\n")
      expect(lines.length).to be >= 1
      lines.each { |line| expect { JSON.parse(line) }.not_to raise_error }
    end
  end
end
