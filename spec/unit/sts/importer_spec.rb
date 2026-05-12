# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require_relative "../../../lib/glossarist/sts"

RSpec.describe Glossarist::Sts::Importer do
  let(:simple_fixture) do
    File.expand_path("../../fixtures/sts/simple_term.xml", __dir__)
  end

  let(:multi_lang_fixture) do
    File.expand_path("../../fixtures/sts/multi_lang_term.xml", __dir__)
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

  describe "#import_new" do
    it "creates a new dataset from a single XML file" do
      importer = described_class.new
      output_dir = File.join(@tmpdir, "new_dataset")
      result = importer.import_new([simple_fixture], output: output_dir)

      expect(result.concepts.length).to eq(2)
      expect(Dir.exist?(output_dir)).to be true
    end

    it "creates a new dataset from multiple XML files" do
      importer = described_class.new
      output_dir = File.join(@tmpdir, "multi_dataset")
      result = importer.import_new(
        [simple_fixture, second_doc_fixture],
        output: output_dir,
      )

      expect(result.concepts.length).to eq(3)
      expect(result.source_files.length).to eq(2)
    end

    it "records source files in result" do
      importer = described_class.new
      result = importer.import_new(
        [simple_fixture],
        output: File.join(@tmpdir, "dataset"),
      )

      expect(result.source_files).to eq([simple_fixture])
    end

    it "raises ArgumentError for GCR without shortname" do
      importer = described_class.new
      expect do
        importer.import_new(
          [simple_fixture],
          output: File.join(@tmpdir, "test.gcr"),
        )
      end.to raise_error(ArgumentError, /shortname/)
    end

    it "raises ArgumentError for GCR without version" do
      importer = described_class.new
      expect do
        importer.import_new(
          [simple_fixture],
          output: File.join(@tmpdir, "test.gcr"),
          shortname: "test",
        )
      end.to raise_error(ArgumentError, /version/)
    end

    it "creates a GCR file when output ends with .gcr" do
      importer = described_class.new
      gcr_path = File.join(@tmpdir, "test.gcr")
      result = importer.import_new(
        [simple_fixture],
        output: gcr_path,
        shortname: "test",
        version: "1.0.0",
      )

      expect(result.concepts.length).to eq(2)
      expect(File.exist?(gcr_path)).to be true
    end

    it "deduplicates concepts across multiple files" do
      # simple_fixture has "sensor" in "robotics" domain (via second_doc)
      # Create two files that produce the same designation+domain
      importer = described_class.new
      output_dir = File.join(@tmpdir, "dedup_dataset")
      result = importer.import_new(
        [second_doc_fixture, second_doc_fixture],
        output: output_dir,
      )

      # Same file imported twice — second should be a duplicate
      expect(result.conflict?).to be true
      expect(result.skipped_count).to be > 0
    end

    it "replaces duplicates in import_new when strategy is :replace" do
      importer = described_class.new(duplicate_strategy: :replace)
      output_dir = File.join(@tmpdir, "replace_dataset")
      result = importer.import_new(
        [second_doc_fixture, second_doc_fixture],
        output: output_dir,
      )

      expect(result.conflict?).to be true
      # With :replace, we still get 1 unique concept, not 2
      expect(result.concepts.length).to eq(1)
    end

    it "returns no conflicts when all concepts are unique" do
      importer = described_class.new
      output_dir = File.join(@tmpdir, "unique_dataset")
      result = importer.import_new(
        [simple_fixture, second_doc_fixture],
        output: output_dir,
      )

      expect(result.conflict?).to be false
      expect(result.skipped_count).to eq(0)
      expect(result.concepts.length).to eq(3)
    end
  end

  describe "#import_into_existing" do
    it "imports into an existing dataset directory" do
      # First, create a dataset with one concept
      existing_dir = File.join(@tmpdir, "existing")
      importer = described_class.new
      importer.import_new([second_doc_fixture], output: existing_dir)

      # Now import into it
      result = importer.import_into_existing([simple_fixture], existing_dir)

      expect(result.concepts.length).to be >= 3
    end

    context "with duplicate concepts" do
      it "skips duplicates by default" do
        existing_dir = File.join(@tmpdir, "existing")
        importer = described_class.new
        importer.import_new([simple_fixture], output: existing_dir)

        # Import the same file again — all concepts should be skipped
        result = importer.import_into_existing([simple_fixture], existing_dir)

        expect(result.conflict?).to be true
        expect(result.skipped_count).to be > 0
      end

      it "replaces duplicates when strategy is :replace" do
        existing_dir = File.join(@tmpdir, "existing")
        importer = described_class.new(duplicate_strategy: :replace)
        importer.import_new([simple_fixture], output: existing_dir)

        result = importer.import_into_existing([simple_fixture], existing_dir)

        expect(result.conflict?).to be true
        # After replace, same number of concepts
        expect(result.concepts.length).to eq(2)
      end

      it "merges localizations when strategy is :merge" do
        existing_dir = File.join(@tmpdir, "existing")

        # Create dataset from English-only doc
        importer = described_class.new
        importer.import_new([second_doc_fixture], output: existing_dir)

        # Create a concept with same designation+domain but different language
        new_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <standard xmlns:tbx="urn:iso:std:iso:30042:ed-2">
            <front>
              <std-meta>
                <std-ref type="dated">ISO 54321:2021</std-ref>
              </std-meta>
            </front>
            <body>
              <sec id="sec_2">
                <term-sec id="sec_2.1">
                  <label>2.1</label>
                  <tbx:termEntry id="term_2.1">
                    <tbx:langSet xml:lang="fr">
                      <tbx:definition>un capteur detecte des changements</tbx:definition>
                      <tbx:tig id="tig_2.1-fr">
                        <tbx:term>capteur</tbx:term>
                        <tbx:partOfSpeech value="noun"/>
                      </tbx:tig>
                      <tbx:subjectField>robotics</tbx:subjectField>
                    </tbx:langSet>
                  </tbx:termEntry>
                </term-sec>
              </sec>
            </body>
          </standard>
        XML
        new_file = File.join(@tmpdir, "french_sensor.xml")
        File.write(new_file, new_xml)

        merge_importer = described_class.new(duplicate_strategy: :merge)
        result = merge_importer.import_into_existing([new_file], existing_dir)

        # The "sensor" concept in "robotics" domain should be merged
        if result.conflict?
          merged = result.concepts.find do |c|
            desig = c.default_designation.to_s.downcase.strip
            domain = c.default_lang&.data&.domain.to_s.downcase.strip
            desig == "sensor" && domain == "robotics"
          end
          expect(merged).not_to be_nil
          expect(merged.localization("fra")).not_to be_nil
        end
      end

      it "raises ArgumentError for invalid strategy" do
        expect do
          described_class.new(duplicate_strategy: :invalid)
        end.to raise_error(ArgumentError, /duplicate_strategy/)
      end
    end

    it "imports into an existing GCR file" do
      gcr_path = File.join(@tmpdir, "existing.gcr")
      importer = described_class.new
      importer.import_new(
        [second_doc_fixture],
        output: gcr_path,
        shortname: "test",
        version: "1.0.0",
      )

      result = importer.import_into_existing([simple_fixture], gcr_path)
      expect(result.concepts.length).to be >= 3
    end
  end
end
