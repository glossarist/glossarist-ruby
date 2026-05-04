# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Glossarist::DatasetValidator do
  let(:validator) { described_class.new }

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
                                                  },
                                                })
    mc.add_localization(l10n)
    mc
  end

  def create_valid_directory
    dir = File.join(@tmpdir, "dataset")
    concepts_dir = File.join(dir, "concepts")
    FileUtils.mkdir_p(concepts_dir)

    concept = {
      "termid" => "100",
      "eng" => {
        "terms" => [{ "type" => "expression", "designation" => "test" }],
        "definition" => [{ "content" => "test definition" }],
      },
    }
    File.write(File.join(concepts_dir, "100.yaml"), YAML.dump(concept))
    dir
  end

  def create_valid_gcr
    output = File.join(@tmpdir, "test.gcr")
    concepts = [build_managed_concept("100", "test", "test definition")]
    metadata = Glossarist::GcrMetadata.new(
      shortname: "test",
      version: "1.0.0",
      concept_count: 1,
      languages: ["eng"],
      schema_version: "1",
    )
    Glossarist::GcrPackage.create(
      concepts: concepts,
      metadata: metadata,
      register_data: nil,
      output_path: output,
    )
    GC.start
    output
  end

  describe "structure validation dispatch" do
    it "validates a .gcr file" do
      gcr_path = create_valid_gcr
      result = validator.validate(gcr_path)
      expect(result).to be_valid
    end

    it "validates a directory" do
      dir = create_valid_directory
      result = validator.validate(dir)
      expect(result).to be_valid
    end

    it "returns errors for invalid .gcr" do
      bad_gcr = File.join(@tmpdir, "bad.gcr")
      result = validator.validate(bad_gcr)
      expect(result).not_to be_valid
      expect(result.errors).to include(a_string_matching(/File not found/))
    end

    it "returns errors for directory with bad YAML" do
      dir = File.join(@tmpdir, "bad_dataset")
      concepts_dir = File.join(dir, "concepts")
      FileUtils.mkdir_p(concepts_dir)
      File.write(File.join(concepts_dir, "bad.yaml"), "not: valid: yaml: [")

      result = validator.validate(dir)
      expect(result).not_to be_valid
    end
  end

  describe "cross-reference validation" do
    def create_reference_gcr(shortname, concepts, uri_prefix: nil)
      path = File.join(@tmpdir, "refs", "#{shortname}.gcr")
      FileUtils.mkdir_p(File.dirname(path))
      metadata = Glossarist::GcrMetadata.new(
        shortname: shortname,
        version: "1.0.0",
        concept_count: concepts.length,
        languages: ["eng"],
        schema_version: "1",
        uri_prefix: uri_prefix,
      )
      Glossarist::GcrPackage.create(
        concepts: concepts,
        metadata: metadata,
        register_data: nil,
        output_path: path,
      )
      GC.start
      path
    end

    it "reports warnings for unresolvable inter-set references" do
      ref_dir = File.join(@tmpdir, "refs")
      FileUtils.mkdir_p(ref_dir)

      target = create_valid_directory
      concept = {
        "termid" => "100",
        "eng" => {
          "terms" => [{ "type" => "expression", "designation" => "test" }],
          "definition" => [{ "content" => "See {{missing, urn:unknown:std:999}}" }],
        },
      }
      File.write(File.join(target, "concepts", "100.yaml"), YAML.dump(concept))

      result = validator.validate(target, reference_path: ref_dir)
      expect(result.warnings.size).to be >= 1
      expect(result.warnings.first).to include("inter-set")
    end

    it "reports warnings for unresolvable intra-set references" do
      ref_dir = File.join(@tmpdir, "refs")
      FileUtils.mkdir_p(ref_dir)

      target = create_valid_directory
      concept = {
        "termid" => "100",
        "eng" => {
          "terms" => [{ "type" => "expression", "designation" => "test" }],
          "definition" => [{ "content" => "See {{missing, 999}}" }],
        },
      }
      File.write(File.join(target, "concepts", "100.yaml"), YAML.dump(concept))

      result = validator.validate(target, reference_path: ref_dir)
      expect(result.warnings.size).to be >= 1
      expect(result.warnings.first).to include("intra-set")
    end

    it "returns no warnings when all references resolve" do
      ref_dir = File.join(@tmpdir, "refs")
      iev_concept = build_managed_concept("102-01-01", "equality",
                                          "equality concept")
      create_reference_gcr("iev", [iev_concept],
                           uri_prefix: "urn:iec:std:iec:60050")

      target = create_valid_directory
      concept = {
        "termid" => "100",
        "eng" => {
          "terms" => [{ "type" => "expression", "designation" => "test" }],
          "definition" => [{ "content" => "See {{equality, urn:iec:std:iec:60050-102-01-01}}" }],
        },
      }
      File.write(File.join(target, "concepts", "100.yaml"), YAML.dump(concept))

      result = validator.validate(target, reference_path: ref_dir)
      expect(result.warnings).to be_empty
    end

    it "handles empty reference_path directory" do
      ref_dir = File.join(@tmpdir, "empty_refs")
      FileUtils.mkdir_p(ref_dir)

      target = create_valid_directory
      result = validator.validate(target, reference_path: ref_dir)
      expect(result).to be_valid
    end

    it "validates cross-references for .gcr input" do
      ref_dir = File.join(@tmpdir, "refs")
      iev_concept = build_managed_concept("102-01-01", "equality",
                                          "equality concept")
      create_reference_gcr("iev", [iev_concept],
                           uri_prefix: "urn:iec:std:iec:60050")

      output = File.join(@tmpdir, "target.gcr")
      target_concept = build_managed_concept(
        "100", "test", "See {{equality, urn:iec:std:iec:60050-102-01-01}}"
      )
      metadata = Glossarist::GcrMetadata.new(
        shortname: "target",
        version: "1.0.0",
        concept_count: 1,
        languages: ["eng"],
        schema_version: "1",
        uri_prefix: "urn:example:target",
      )
      Glossarist::GcrPackage.create(
        concepts: [target_concept],
        metadata: metadata,
        register_data: nil,
        output_path: output,
      )
      GC.start

      result = validator.validate(output, reference_path: ref_dir)
      expect(result.warnings).to be_empty
    end
  end
end
