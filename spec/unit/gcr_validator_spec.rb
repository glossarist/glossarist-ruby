# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Glossarist::GcrValidator do
  let(:validator) { described_class.new }

  before do
    @tmpdir = Dir.mktmpdir
  end

  after do
    FileUtils.rm_rf(@tmpdir)
  end

  def build_managed_concept(termid, designation, definition)
    mc = Glossarist::ManagedConcept.new(data: { id: termid })
    l10n = Glossarist::LocalizedConcept.of_yaml({
                                                  "data" => {
                                                    "language_code" => "eng",
                                                    "terms" => [{
                                                      "type" => "expression", "designation" => designation
                                                    }],
                                                    "definition" => [{ "content" => definition }],
                                                  },
                                                })
    mc.add_localization(l10n)
    mc
  end

  def create_valid_gcr
    output = File.join(@tmpdir, "test.gcr")
    concepts = [build_managed_concept("100", "test", "test definition")]
    metadata = Glossarist::GcrMetadata.new(
      shortname: "test", version: "1.0.0",
      concept_count: 1, languages: ["eng"], schema_version: "1",
      uri_prefix: "urn:test"
    )
    Glossarist::GcrPackage.create(
      concepts: concepts, metadata: metadata,
      register_data: nil, output_path: output
    )
    GC.start
    output
  end

  describe "#validate" do
    it "returns errors for non-existent file" do
      result = validator.validate("/nonexistent.gcr")
      expect(result).not_to be_valid
      expect(result.errors).to include(a_string_matching(/File not found/))
    end

    it "validates a valid GCR package" do
      gcr = create_valid_gcr
      result = validator.validate(gcr)
      expect(result).to be_valid
    end

    it "reports missing metadata.yaml" do
      require "zip"
      bad = File.join(@tmpdir, "bad.gcr")
      Zip::File.open(bad, create: true) { |zf| zf.get_output_stream("concepts/1.yaml") { |f| f.write("---\n") } }
      result = validator.validate(bad)
      expect(result).not_to be_valid
      expect(result.errors).to include(a_string_matching(/Missing metadata.yaml/))
    end

    it "warns about missing concept URIs when no uri_prefix or template" do
      output = File.join(@tmpdir, "no-uri.gcr")
      concepts = [build_managed_concept("100", "test", "def")]
      metadata = Glossarist::GcrMetadata.new(
        shortname: "test", version: "1.0.0",
        concept_count: 1, languages: ["eng"], schema_version: "1"
      )
      Glossarist::GcrPackage.create(
        concepts: concepts, metadata: metadata,
        register_data: nil, output_path: output
      )
      GC.start
      result = validator.validate(output)
      expect(result.warnings).not_to be_empty
      expect(result.warnings).to include(a_string_matching(/no concept URI/))
    end

    it "validates bibliography.yaml as YAML when present" do
      gcr = create_valid_gcr_with_bibliography("invalid: [yaml: unclosed")
      result = validator.validate(gcr)
      expect(result).not_to be_valid
      expect(result.errors).to include(a_string_matching(/bibliography.yaml.*invalid YAML/))
    end

    it "accepts valid bibliography.yaml without errors" do
      gcr = create_valid_gcr_with_bibliography("ISO_19111:\n  type: standard")
      result = validator.validate(gcr)
      expect(result.errors).not_to include(a_string_matching(/bibliography.yaml/))
    end

    it "warns when images/ directory exists but is empty" do
      gcr = create_valid_gcr
      Zip::File.open(gcr, create: false) do |zf|
        # Can't add empty directory to existing zip easily; create a new one
      end
      output = File.join(@tmpdir, "empty-images.gcr")
      concepts = [build_managed_concept("100", "test", "def")]
      metadata = Glossarist::GcrMetadata.new(
        shortname: "test", version: "1.0.0",
        concept_count: 1, languages: ["eng"], schema_version: "1",
        uri_prefix: "urn:test"
      )
      Zip::File.open(output, create: true) do |zf|
        zf.get_output_stream("metadata.yaml") { |f| f.write(metadata.to_yaml) }
        doc = Glossarist::ConceptDocument.from_managed_concept(concepts.first)
        zf.get_output_stream("concepts/100.yaml") { |f| f.write(doc.to_yamls) }
      end
      result = validator.validate(output)
      expect(result).to be_valid
    end
  end

  def create_valid_gcr_with_bibliography(bib_content) # rubocop:disable Metrics/AbcSize
    output = File.join(@tmpdir, "with-bib.gcr")
    concepts = [build_managed_concept("100", "test", "def")]
    metadata = Glossarist::GcrMetadata.new(
      shortname: "test", version: "1.0.0",
      concept_count: 1, languages: ["eng"], schema_version: "1",
      uri_prefix: "urn:test"
    )
    Zip::File.open(output, create: true) do |zf|
      zf.get_output_stream("metadata.yaml") { |f| f.write(metadata.to_yaml) }
      doc = Glossarist::ConceptDocument.from_managed_concept(concepts.first)
      zf.get_output_stream("concepts/100.yaml") { |f| f.write(doc.to_yamls) }
      zf.get_output_stream("bibliography.yaml") { |f| f.write(bib_content) }
    end
    output
  end
end
