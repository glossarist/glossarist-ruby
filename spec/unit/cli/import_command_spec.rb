# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require_relative "../../../lib/glossarist/cli/import_command"

RSpec.describe Glossarist::CLI::ImportCommand do
  let(:simple_fixture) do
    File.expand_path("../../fixtures/sts/simple_term.xml", __dir__)
  end

  let(:second_doc_fixture) do
    File.expand_path("../../fixtures/sts/second_doc.xml", __dir__)
  end

  before do
    @tmpdir = Dir.mktmpdir
  end

  after do
    FileUtils.rm_rf(@tmpdir)
  end

  describe "#run" do
    it "creates a new dataset from STS XML" do
      output_dir = File.join(@tmpdir, "new_dataset")
      options = { output: output_dir }
      command = described_class.new([simple_fixture], options)

      expect do
        command.run
      end.to output(/Imported 2 concepts/).to_stdout

      expect(Dir.exist?(output_dir)).to be true
    end

    it "creates a GCR file" do
      gcr_path = File.join(@tmpdir, "test.gcr")
      options = {
        output: gcr_path,
        shortname: "test",
        version: "1.0.0",
      }
      command = described_class.new([simple_fixture], options)

      expect do
        command.run
      end.to output(/Imported 2 concepts/).to_stdout

      expect(File.exist?(gcr_path)).to be true
    end

    it "imports into an existing dataset" do
      existing_dir = File.join(@tmpdir, "existing")
      described_class.new([second_doc_fixture], { output: existing_dir }).run

      command = described_class.new([simple_fixture], { into: existing_dir })
      expect do
        command.run
      end.to output(/Imported \d+ concepts/).to_stdout
    end

    it "reports duplicate count" do
      existing_dir = File.join(@tmpdir, "existing")
      described_class.new([simple_fixture], { output: existing_dir }).run

      command = described_class.new(
        [simple_fixture],
        { into: existing_dir, on_duplicate: "skip" },
      )
      expect do
        command.run
      end.to output(/duplicate\(s\) detected/).to_stdout
    end

    it "exits with error for invalid arguments" do
      options = { output: File.join(@tmpdir, "test.gcr") }
      command = described_class.new([simple_fixture], options)

      expect do
        command.run
      end.to output(/Error:.*shortname/).to_stderr.and raise_error(SystemExit)
    end

    it "uses on_duplicate option" do
      existing_dir = File.join(@tmpdir, "existing")
      described_class.new([simple_fixture], { output: existing_dir }).run

      command = described_class.new(
        [simple_fixture],
        { into: existing_dir, on_duplicate: "replace" },
      )
      expect do
        command.run
      end.to output(/strategy: replace/).to_stdout
    end
  end
end
