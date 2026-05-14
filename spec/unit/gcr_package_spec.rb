# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Glossarist::GcrPackage do
  let(:sample_concepts) do
    [
      build_managed_concept("102-01-01", "equality", "test definition"),
      build_managed_concept("102-01-02", "quantity", "another definition"),
    ]
  end

  let(:sample_metadata) do
    Glossarist::GcrMetadata.new(
      shortname: "test",
      version: "1.0.0",
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

  def build_managed_concept(termid, designation, definition_content)
    mc = Glossarist::ManagedConcept.new(data: { id: termid })
    l10n = Glossarist::LocalizedConcept.of_yaml({
                                                  "data" => {
                                                    "language_code" => "eng",
                                                    "terms" => [{
                                                      "type" => "expression", "designation" => designation
                                                    }],
                                                    "definition" => [{ "content" => definition_content }],
                                                    "entry_status" => "valid",
                                                  },
                                                })
    mc.add_localization(l10n)
    mc
  end

  def create_test_gcr(register: nil)
    register_data = register ? Glossarist::RegisterData.of_yaml(register) : nil
    described_class.create(
      concepts: sample_concepts,
      metadata: sample_metadata,
      register_data: register_data,
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

    it "writes multi-document YAML for each concept" do
      create_test_gcr

      Zip::File.open(gcr_path) do |zf|
        entry = zf.find_entry("concepts/102-01-01.yaml")
        doc = Glossarist::ConceptDocument.from_yamls(entry.get_input_stream.read)
        expect(doc.concept).to be_a(Glossarist::ManagedConcept)
        expect(doc.localizations.length).to eq(1)
        expect(doc.concept.data.id).to eq("102-01-01")
        expect(doc.localizations.first.language_code).to eq("eng")
      end
    end

    it "includes register.yaml when provided" do
      register = { "name" => "Test", "schema_version" => "1" }
      create_test_gcr(register: register)

      Zip::File.open(gcr_path) do |zf|
        expect(zf.find_entry("register.yaml")).not_to be_nil
        rd = Glossarist::RegisterData.from_yaml(zf.find_entry("register.yaml").get_input_stream.read)
        expect(rd["name"]).to eq("Test")
      end
    end
  end

  describe ".load" do
    it "loads concepts from a .gcr file" do
      create_test_gcr

      package = described_class.load(gcr_path)
      expect(package.concepts.length).to eq(2)
      ids = package.concepts.map { |mc| mc.data.id }
      expect(ids).to contain_exactly("102-01-01", "102-01-02")
    end

    it "loads concepts as ManagedConcept objects" do
      create_test_gcr

      package = described_class.load(gcr_path)
      package.concepts.each do |mc|
        expect(mc).to be_a(Glossarist::ManagedConcept)
        expect(mc.localization("eng")).to be_a(Glossarist::LocalizedConcept)
      end
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
      mc = pkg.concepts.first
      l10n = mc.localization("eng")
      expect(l10n.data.references).not_to be_empty
      ids = l10n.data.references.map(&:concept_id)
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
      mc = pkg.concepts.first
      l10n = mc.localization("eng")
      ref = l10n.data.references.first
      expect(ref.source).to eq("urn:iso:std:iso:19111")
      expect(ref.concept_id).to eq("3.1.32")
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

  describe "compiled formats" do
    before do
      @tmpdir = Dir.mktmpdir
    end

    after do
      FileUtils.rm_rf(@tmpdir)
    end

    def create_v1_dataset_for_compiled
      source = File.join(@tmpdir, "source")
      concepts_dir = File.join(source, "concepts")
      FileUtils.mkdir_p(concepts_dir)

      concept = {
        "termid" => "100",
        "term" => "latitude",
        "eng" => {
          "terms" => [{ "type" => "expression", "designation" => "latitude" }],
          "definition" => [{ "content" => "angular distance" }],
        },
      }
      File.write(File.join(concepts_dir, "100.yaml"), YAML.dump(concept))
      source
    end

    it "bundles TBX compiled format" do
      source = create_v1_dataset_for_compiled
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
        compiled_formats: ["tbx"],
      )

      Zip::File.open(output) do |zf|
        entry = zf.find_entry("compiled/test.tbx.xml")
        expect(entry).not_to be_nil
        content = entry.get_input_stream.read
        expect(content).to include("<tbx")
      end
    end

    it "bundles JSON-LD compiled format" do
      source = create_v1_dataset_for_compiled
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
        compiled_formats: ["jsonld"],
      )

      Zip::File.open(output) do |zf|
        entry = zf.find_entry("compiled/test.jsonld")
        expect(entry).not_to be_nil
        parsed = JSON.parse(entry.get_input_stream.read)
        expect(parsed["@context"]).to include("skos")
        expect(parsed["@graph"]).to be_an(Array)
      end
    end

    it "bundles Turtle compiled format" do
      source = create_v1_dataset_for_compiled
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
        compiled_formats: ["turtle"],
      )

      Zip::File.open(output) do |zf|
        entry = zf.find_entry("compiled/test.ttl")
        expect(entry).not_to be_nil
        content = entry.get_input_stream.read
        expect(content).to include("@prefix skos:")
        expect(content).to include("skos:Concept")
      end
    end

    it "bundles JSONL compiled format" do
      source = create_v1_dataset_for_compiled
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
        compiled_formats: ["jsonl"],
      )

      Zip::File.open(output) do |zf|
        entry = zf.find_entry("compiled/test.jsonl")
        expect(entry).not_to be_nil
        lines = entry.get_input_stream.read.strip.split("\n")
        expect(lines.length).to be >= 1
        lines.each { |line| expect { JSON.parse(line) }.not_to raise_error }
      end
    end

    it "warns on unknown compiled format" do
      source = create_v1_dataset_for_compiled
      output = File.join(@tmpdir, "output.gcr")

      expect do
        described_class.create_from_directory(
          source,
          output: output,
          shortname: "test",
          version: "1.0.0",
          compiled_formats: ["unknown"],
        )
      end.to output(/Unknown compiled format/).to_stderr
    end

    it "raises error when compiled formats used with streaming" do
      source = create_v1_dataset_for_compiled
      output = File.join(@tmpdir, "output.gcr")

      expect do
        described_class.create_from_directory(
          source,
          output: output,
          shortname: "test",
          version: "1.0.0",
          compiled_formats: ["jsonld"],
          streaming: true,
        )
      end.to raise_error(ArgumentError, /batch mode/)
    end

    it "records compiled_formats in metadata" do
      source = create_v1_dataset_for_compiled
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
        compiled_formats: ["jsonld", "turtle"],
      )

      pkg = described_class.load(output)
      expect(pkg.metadata.compiled_formats).to contain_exactly("jsonld",
                                                               "turtle")
    end
  end

  describe "bibliography and images" do
    before do
      @tmpdir = Dir.mktmpdir
    end

    after do
      FileUtils.rm_rf(@tmpdir)
    end

    def create_source_with_assets(include_bibliography: true, # rubocop:disable Metrics/AbcSize
                                   include_images: true)
      source = File.join(@tmpdir, "source")
      concepts_dir = File.join(source, "concepts")
      FileUtils.mkdir_p(concepts_dir)

      concept = {
        "termid" => "100",
        "term" => "latitude",
        "eng" => {
          "terms" => [{ "type" => "expression", "designation" => "latitude" }],
          "definition" => [{ "content" => "angular distance" }],
        },
      }
      File.write(File.join(concepts_dir, "100.yaml"), YAML.dump(concept))

      if include_bibliography
        write_test_bibliography(source)
      end

      if include_images
        write_test_images(source)
      end

      source
    end

    def write_test_bibliography(source)
      bib = {
        "ISO_19111_2019" => {
          "type" => "standard",
          "title" => "Geographic information — Referencing by coordinates",
        },
      }
      File.write(File.join(source, "bibliography.yaml"), YAML.dump(bib))
    end

    def write_test_images(source)
      FileUtils.mkdir_p(File.join(source, "images", "diagrams"))
      File.binwrite(File.join(source, "images", "figure1.png"),
                    "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR")
      File.binwrite(File.join(source, "images", "diagrams", "schema.png"),
                    "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR2")
    end

    it "includes bibliography.yaml in batch mode" do
      source = create_source_with_assets(include_images: false)
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
      )

      Zip::File.open(output) do |zf|
        entry = zf.find_entry("bibliography.yaml")
        expect(entry).not_to be_nil
        parsed = YAML.safe_load(entry.get_input_stream.read)
        expect(parsed).to have_key("ISO_19111_2019")
      end
    end

    it "includes images/ in batch mode" do
      source = create_source_with_assets(include_bibliography: false)
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
      )

      Zip::File.open(output) do |zf|
        expect(zf.find_entry("images/figure1.png")).not_to be_nil
        expect(zf.find_entry("images/diagrams/schema.png")).not_to be_nil
      end
    end

    it "skips bibliography.yaml when absent" do
      source = create_source_with_assets(include_bibliography: false,
                                         include_images: false)
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
      )

      Zip::File.open(output) do |zf|
        expect(zf.find_entry("bibliography.yaml")).to be_nil
      end
    end

    it "skips images/ when absent" do
      source = create_source_with_assets(include_bibliography: false,
                                         include_images: false)
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
      )

      Zip::File.open(output) do |zf|
        image_entries = zf.entries.select { |e| e.name.start_with?("images/") }
        expect(image_entries).to be_empty
      end
    end

    it "preserves binary content of images" do
      source = create_source_with_assets(include_bibliography: false)
      original = File.binread(File.join(source, "images", "figure1.png"))
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
      )

      Zip::File.open(output) do |zf|
        content = zf.find_entry("images/figure1.png").get_input_stream.read
        expect(content.bytes).to eq(original.bytes)
      end
    end

    it "reads bibliography from loaded GCR" do
      source = create_source_with_assets(include_images: false)
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
      )

      pkg = described_class.load(output)
      expect(pkg.bibliography).not_to be_nil
      parsed = YAML.safe_load(pkg.bibliography)
      expect(parsed).to have_key("ISO_19111_2019")
    end

    it "returns nil bibliography when GCR has none" do
      source = create_source_with_assets(include_bibliography: false,
                                         include_images: false)
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
      )

      pkg = described_class.load(output)
      expect(pkg.bibliography).to be_nil
    end

    it "includes bibliography in streaming mode" do
      source = create_source_with_assets(include_images: false)
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
        streaming: true,
      )

      Zip::File.open(output) do |zf|
        expect(zf.find_entry("bibliography.yaml")).not_to be_nil
      end
    end

    it "includes images in streaming mode" do
      source = create_source_with_assets(include_bibliography: false)
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
        streaming: true,
      )

      Zip::File.open(output) do |zf|
        expect(zf.find_entry("images/figure1.png")).not_to be_nil
        expect(zf.find_entry("images/diagrams/schema.png")).not_to be_nil
      end
    end

    it "includes both bibliography and images in streaming mode" do
      source = create_source_with_assets
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
        streaming: true,
      )

      Zip::File.open(output) do |zf|
        expect(zf.find_entry("bibliography.yaml")).not_to be_nil
        expect(zf.find_entry("images/figure1.png")).not_to be_nil
        expect(zf.find_entry("concepts/100.yaml")).not_to be_nil
        expect(zf.find_entry("metadata.yaml")).not_to be_nil
      end
    end

    it "round-trips bibliography through create_from_directory → load" do
      source = create_source_with_assets(include_images: false)
      original_bib = File.binread(File.join(source, "bibliography.yaml"))
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
      )

      pkg = described_class.load(output)
      expect(pkg.bibliography.bytes).to eq(original_bib.bytes)
    end

    it "round-trips images through create_from_directory → zip inspection" do
      source = create_source_with_assets(include_bibliography: false)
      original = File.binread(File.join(source, "images", "diagrams",
                                        "schema.png"))
      output = File.join(@tmpdir, "output.gcr")

      described_class.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
      )

      Zip::File.open(output) do |zf|
        round_tripped = zf.find_entry("images/diagrams/schema.png").get_input_stream.read
        expect(round_tripped.bytes).to eq(original.bytes)
      end
    end
  end
end
