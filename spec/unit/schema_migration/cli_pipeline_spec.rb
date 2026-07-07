# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Glossarist::SchemaMigration::CliPipeline do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:source_dir) { File.join(tmpdir, "source") }
  let(:output_dir) { File.join(tmpdir, "out") }

  def write_v0_dataset(dir)
    FileUtils.mkdir_p(File.join(dir, "concepts"))
    File.write(File.join(dir, "concepts", "1.yaml"), <<~YAML, encoding: "utf-8")
      ---
      termid: '1'
      eng:
        terms:
        - designation: alpha
          type: expression
          normative_status: preferred
        definition:
        - content: a definition
        entry_status: valid
    YAML
    File.write(File.join(dir, "register.yaml"), <<~YAML, encoding: "utf-8")
      ---
      schema_version: '0'
      shortname: test
    YAML
  end

  describe "#initialize" do
    it "expands the source directory path" do
      pipeline = described_class.new("relative/path", output: "/out",
                                                   target_version: "1")
      expect(pipeline.source_dir).to eq(File.expand_path("relative/path"))
    end

    it "exposes accessors for source_dir, output, target_version, dry_run" do
      pipeline = described_class.new("/src", output: "/out",
                                                   target_version: "1",
                                                   cross_references: "x.yaml",
                                                   dry_run: true)
      expect(pipeline.source_dir).to eq("/src")
      expect(pipeline.output).to eq("/out")
      expect(pipeline.target_version).to eq("1")
      expect(pipeline.cross_references).to eq("x.yaml")
      expect(pipeline.dry_run).to be true
    end
  end

  describe "#run" do
    it "raises ArgumentError when source is not a directory" do
      pipeline = described_class.new("/nonexistent", output: output_dir,
                                                    target_version: "1")
      expect { pipeline.run }.to raise_error(ArgumentError, /not a directory/)
    end

    it "raises ArgumentError when no concept files are found" do
      FileUtils.mkdir_p(source_dir)
      pipeline = described_class.new(source_dir, output: output_dir,
                                                   target_version: "1")
      expect { pipeline.run }.to raise_error(ArgumentError, /No concept YAML/)
    end

    it "migrates each concept and writes YAML to output/concepts/" do
      write_v0_dataset(source_dir)
      result = described_class.new(
        source_dir, output: output_dir, target_version: "1",
      ).run
      expect(File.exist?(File.join(output_dir, "concepts", "1.yaml"))).to be true
      expect(result[:count]).to eq(1)
      expect(result[:source_version]).to eq("0")
      expect(result[:target_version]).to eq("1")
    end

    it "writes register.yaml at the output root when register existed" do
      write_v0_dataset(source_dir)
      described_class.new(
        source_dir, output: output_dir, target_version: "1",
      ).run
      expect(File.exist?(File.join(output_dir, "register.yaml"))).to be true
    end
  end

  describe "dry_run" do
    it "prints intent and writes nothing" do
      write_v0_dataset(source_dir)
      pipeline = described_class.new(
        source_dir, output: File.join(tmpdir, "dry.gcr"),
        target_version: "1", dry_run: true,
      )
      expect { pipeline.run }.to output(/Would package 1 concepts/).to_stdout
      expect(File.exist?(File.join(tmpdir, "dry.gcr"))).to be false
    end
  end
end
