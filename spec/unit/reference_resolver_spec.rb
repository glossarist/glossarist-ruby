# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::ReferenceResolver do
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

  let(:iso_concepts) do
    [
      {
        "termid" => "3.1.32",
        "term" => "geodetic latitude",
        "eng" => {
          "terms" => [{ "designation" => "geodetic latitude" }],
          "definition" => [{ "content" => "test" }],
        },
      },
    ]
  end

  describe "#register_self and #resolve" do
    it "resolves local references via local adapter" do
      resolver = described_class.new
      resolver.register_self(iev_concepts)

      ref = Glossarist::ConceptReference.new(
        term: "test", concept_id: "102-01-01", source: nil, ref_type: "local",
      )
      result = resolver.resolve(ref)

      expect(result).not_to be_nil
      expect(result["termid"]).to eq("102-01-01")
    end
  end

  describe "#register_package and #resolve" do
    it "resolves URN references by matching uri_prefix" do
      resolver = described_class.new
      resolver.register_package(iev_concepts,
                                uri_prefix: "urn:iec:std:iec:60050")

      ref = Glossarist::ConceptReference.new(
        term: "equality", concept_id: "102-01-01",
        source: "urn:iec:std:iec:60050", ref_type: "urn"
      )
      result = resolver.resolve(ref)

      expect(result).not_to be_nil
      expect(result["termid"]).to eq("102-01-01")
    end

    it "returns nil when uri_prefix does not match" do
      resolver = described_class.new
      resolver.register_package(iev_concepts,
                                uri_prefix: "urn:iec:std:iec:60050")

      ref = Glossarist::ConceptReference.new(
        term: "lat", concept_id: "3.1.32",
        source: "urn:iso:std:iso:19111", ref_type: "urn"
      )
      expect(resolver.resolve(ref)).to be_nil
    end

    it "returns nil for unknown concept_id within a matching package" do
      resolver = described_class.new
      resolver.register_package(iev_concepts,
                                uri_prefix: "urn:iec:std:iec:60050")

      ref = Glossarist::ConceptReference.new(
        term: "missing", concept_id: "999-99-99",
        source: "urn:iec:std:iec:60050", ref_type: "urn"
      )
      expect(resolver.resolve(ref)).to be_nil
    end
  end

  describe "#add_route" do
    it "remaps source URI via route override" do
      resolver = described_class.new
      resolver.register_package(iso_concepts,
                                uri_prefix: "urn:iso:std:iso:19111")
      resolver.add_route(from: "urn:iso:std:iso:19115",
                         to: "urn:iso:std:iso:19111")

      ref = Glossarist::ConceptReference.new(
        term: "lat", concept_id: "3.1.32",
        source: "urn:iso:std:iso:19115", ref_type: "urn"
      )
      result = resolver.resolve(ref)

      expect(result).not_to be_nil
      expect(result["termid"]).to eq("3.1.32")
    end
  end

  describe "#validate_all" do
    it "reports unresolvable external references as warnings" do
      resolver = described_class.new
      resolver.register_self(iev_concepts)

      concept = {
        "termid" => "100",
        "eng" => {
          "definition" => [{ "content" => "See {{eq, urn:iec:std:iec:60050-102-01-01}}" }],
          "terms" => [],
          "notes" => [],
          "examples" => [],
        },
      }

      result = resolver.validate_all([concept])
      expect(result).to be_valid
      expect(result.warnings).not_to be_empty
    end

    it "reports valid when all external references resolve" do
      resolver = described_class.new
      resolver.register_self(iev_concepts)
      resolver.register_package(iev_concepts,
                                uri_prefix: "urn:iec:std:iec:60050")

      concept = {
        "termid" => "100",
        "eng" => {
          "definition" => [{ "content" => "See {{eq, urn:iec:std:iec:60050-102-01-01}}" }],
          "terms" => [],
          "notes" => [],
          "examples" => [],
        },
      }

      result = resolver.validate_all([concept])
      expect(result).to be_valid
    end

    it "reports unresolvable local references as warnings" do
      resolver = described_class.new
      resolver.register_self(iev_concepts)

      concept = {
        "termid" => "100",
        "eng" => {
          "definition" => [{ "content" => "See {{missing, 999}}" }],
          "terms" => [],
          "notes" => [],
          "examples" => [],
        },
      }

      result = resolver.validate_all([concept])
      expect(result).to be_valid
      expect(result.warnings.first).to include("intra-set")
    end
  end

  describe "#registered_datasets" do
    it "returns registered uri_prefixes" do
      resolver = described_class.new
      resolver.register_package(iev_concepts,
                                uri_prefix: "urn:iec:std:iec:60050")
      resolver.register_package(iso_concepts,
                                uri_prefix: "urn:iso:std:iso:19111")

      expect(resolver.registered_datasets).to contain_exactly(
        "urn:iec:std:iec:60050", "urn:iso:std:iso:19111"
      )
    end
  end

  describe "accepts Hash as single concept" do
    it "handles a single concept hash" do
      resolver = described_class.new
      concept = { "termid" => "100",
                  "eng" => { "definition" => [{ "content" => "test" }] } }

      expect do
        resolver.register_package(concept, uri_prefix: "urn:test:1")
      end.not_to raise_error
    end
  end
end
