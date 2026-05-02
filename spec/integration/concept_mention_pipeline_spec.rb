# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe "Concept mention resolution pipeline" do
  let(:extractor) { Glossarist::ReferenceExtractor.new }
  let(:resolver) { Glossarist::ReferenceResolver.new }

  let(:iev_concepts) do
    [
      {
        "termid" => "102-01-01",
        "term" => "equality",
        "eng" => {
          "terms" => [{ "designation" => "equality" }],
          "definition" => [{ "content" => "test" }],
        },
      },
      {
        "termid" => "102-01-02",
        "term" => "quantity",
        "eng" => {
          "terms" => [{ "designation" => "quantity" }],
          "definition" => [{ "content" => "test" }],
        },
      },
    ]
  end

  let(:target_concepts) do
    [
      {
        "termid" => "100",
        "eng" => {
          "terms" => [{ "type" => "expression", "designation" => "latitude" }],
          "definition" => [{ "content" => "See {{equality, urn:iec:std:iec:60050-102-01-01}} and {{quantity, 101}}" }],
          "notes" => [{ "content" => "Also see {{200}} which does not exist" }],
          "examples" => [],
        },
      },
      {
        "termid" => "101",
        "eng" => {
          "terms" => [{ "designation" => "quantity" }],
          "definition" => [{ "content" => "test" }],
        },
      },
    ]
  end

  before do
    resolver.register_self(target_concepts)
    resolver.register_package(iev_concepts, uri_prefix: "urn:iec:std:iec:60050")
  end

  describe "extract → resolve → validate pipeline" do
    it "extracts all reference types from concept text" do
      refs = extractor.extract_from_concept_hash(target_concepts.first)

      expect(refs.size).to eq(3)
      urn_ref = refs.find { |r| r.source == "urn:iec:std:iec:60050" }
      local_ref = refs.find { |r| r.ref_type == "local" && r.concept_id == "101" }
      missing_ref = refs.find { |r| r.concept_id == "200" }

      expect(urn_ref).to be_external
      expect(local_ref).to be_local
      expect(missing_ref).to be_local
    end

    it "resolves URN references to external concepts" do
      refs = extractor.extract_from_concept_hash(target_concepts.first)
      urn_ref = refs.find(&:external?)

      result = resolver.resolve(urn_ref)
      expect(result).not_to be_nil
      expect(result["termid"]).to eq("102-01-01")
    end

    it "resolves local references to self-registered concepts" do
      refs = extractor.extract_from_concept_hash(target_concepts.first)
      local_ref = refs.find { |r| r.concept_id == "101" }

      result = resolver.resolve(local_ref)
      expect(result).not_to be_nil
      expect(result["termid"]).to eq("101")
    end

    it "reports unresolvable references as warnings" do
      result = resolver.validate_all(target_concepts)
      expect(result).to be_valid
      expect(result.warnings).not_to be_empty
      expect(result.warnings).to include(a_string_matching(/200/))
    end
  end

  describe "ConceptReference#to_urn round-trip" do
    it "reconstructs IEC URN from source + concept_id" do
      refs = extractor.extract_from_text("{{equality, urn:iec:std:iec:60050-102-01-01}}")
      expect(refs.first.to_urn).to eq("urn:iec:std:iec:60050-102-01-01")
    end

    it "reconstructs ISO URN from source + concept_id" do
      refs = extractor.extract_from_text("{{lat, urn:iso:std:iso:19111:ed-3:v1:en:term:3.1.32}}")
      expect(refs.first.to_urn).to eq("urn:iso:std:iso:19111:term:3.1.32")
    end

    it "returns nil for local references" do
      refs = extractor.extract_from_text("{{test, 200}}")
      expect(refs.first.to_urn).to be_nil
    end
  end

  describe "UrnResolver integration" do
    it "resolves ConceptReference to HTTP URL" do
      refs = extractor.extract_from_text("{{equality, urn:iec:std:iec:60050-102-01-01}}")
      url = Glossarist::UrnResolver.resolve(refs.first)

      expect(url).to include("electropedia.org")
      expect(url).to include("102-01-01")
    end
  end

  describe "GCR packaging with reference extraction" do
    before do
      @tmpdir = Dir.mktmpdir
    end

    after do
      FileUtils.rm_rf(@tmpdir)
    end

    it "packages and reloads concepts with references intact" do
      source = File.join(@tmpdir, "source")
      concepts_dir = File.join(source, "concepts")
      FileUtils.mkdir_p(concepts_dir)

      concept = {
        "termid" => "100",
        "term" => "latitude",
        "eng" => {
          "terms" => [{ "type" => "expression", "designation" => "latitude" }],
          "definition" => [{ "content" => "See {{equality, urn:iec:std:iec:60050-102-01-01}}" }],
        },
      }
      File.write(File.join(concepts_dir, "100.yaml"), YAML.dump(concept))

      output = File.join(@tmpdir, "test.gcr")
      Glossarist::GcrPackage.create_from_directory(
        source,
        output: output,
        shortname: "test",
        version: "1.0.0",
        uri_prefix: "urn:example:test",
      )

      pkg = Glossarist::GcrPackage.load(output)
      expect(pkg.concepts.length).to eq(1)
      expect(pkg.metadata["uri_prefix"]).to eq("urn:example:test")

      loaded_concept = pkg.concepts.first
      expect(loaded_concept["references"]).to be_a(Array)
      expect(loaded_concept["references"].first["source"]).to eq("urn:iec:std:iec:60050")
    end
  end
end
