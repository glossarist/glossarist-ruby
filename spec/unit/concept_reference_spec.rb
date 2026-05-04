# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::ConceptReference do
  describe "construction" do
    it "builds with all attributes" do
      ref = described_class.new(
        term: "equality",
        concept_id: "102-01-01",
        source: "urn:iec:std:iec:60050",
        ref_type: "urn",
      )

      expect(ref.term).to eq("equality")
      expect(ref.concept_id).to eq("102-01-01")
      expect(ref.source).to eq("urn:iec:std:iec:60050")
      expect(ref.ref_type).to eq("urn")
    end
  end

  describe "#local?" do
    it "returns true for local ref_type" do
      ref = described_class.new(term: "latitude", concept_id: "200",
                                ref_type: "local")
      expect(ref).to be_local
    end

    it "returns true for designation ref_type" do
      ref = described_class.new(term: "geodetic latitude",
                                ref_type: "designation")
      expect(ref).to be_local
    end

    it "returns true when source is empty string" do
      ref = described_class.new(term: "latitude", concept_id: "200",
                                source: "", ref_type: "local")
      expect(ref).to be_local
    end
  end

  describe "#external?" do
    it "returns true when source is present" do
      ref = described_class.new(term: "equality", concept_id: "102-01-01",
                                source: "urn:iec:std:iec:60050", ref_type: "urn")
      expect(ref).to be_external
    end

    it "returns false for local reference" do
      ref = described_class.new(term: "latitude", concept_id: "200",
                                ref_type: "local")
      expect(ref).not_to be_external
    end
  end

  describe "YAML round-trip" do
    it "serializes and deserializes all fields" do
      ref = described_class.new(
        term: "equality",
        concept_id: "102-01-01",
        source: "urn:iec:std:iec:60050",
        ref_type: "urn",
      )

      yaml = ref.to_yaml
      loaded = described_class.from_yaml(yaml)

      expect(loaded.term).to eq("equality")
      expect(loaded.concept_id).to eq("102-01-01")
      expect(loaded.source).to eq("urn:iec:std:iec:60050")
      expect(loaded.ref_type).to eq("urn")
    end

    it "handles internal references (nil source)" do
      ref = described_class.new(
        term: "geodetic latitude",
        concept_id: "200",
        ref_type: "local",
      )

      yaml = ref.to_yaml
      loaded = described_class.from_yaml(yaml)

      expect(loaded.term).to eq("geodetic latitude")
      expect(loaded.concept_id).to eq("200")
      expect(loaded.source).to be_nil
      expect(loaded.ref_type).to eq("local")
      expect(loaded).to be_local
    end
  end

  describe "ConceptData integration" do
    it "ConceptData accepts references collection" do
      ref = described_class.new(term: "equality", concept_id: "102-01-01",
                                source: "urn:iec:std:iec:60050", ref_type: "urn")
      concept_data = Glossarist::ConceptData.new(
        id: "200",
        references: [ref],
      )

      expect(concept_data.references).to eq([ref])
    end

    it "ConceptData serializes references in YAML" do
      ref = described_class.new(term: "equality", concept_id: "102-01-01",
                                source: "urn:iec:std:iec:60050", ref_type: "urn")
      concept_data = Glossarist::ConceptData.new(
        id: "200",
        references: [ref],
      )

      yaml_hash = concept_data.to_yaml_hash
      expect(yaml_hash["references"]).to be_a(Array)
      expect(yaml_hash["references"].first["term"]).to eq("equality")
    end

    it "ConceptData round-trips with references" do
      ref = described_class.new(term: "equality", concept_id: "102-01-01",
                                source: "urn:iec:std:iec:60050", ref_type: "urn")
      concept_data = Glossarist::ConceptData.new(
        id: "200",
        references: [ref],
      )

      yaml = concept_data.to_yaml
      loaded = Glossarist::ConceptData.from_yaml(yaml)

      expect(loaded.references.size).to eq(1)
      expect(loaded.references.first.term).to eq("equality")
      expect(loaded.references.first.concept_id).to eq("102-01-01")
      expect(loaded.references.first.source).to eq("urn:iec:std:iec:60050")
    end
  end

  describe "#to_urn" do
    it "reconstructs IEC URN from source + concept_id" do
      ref = described_class.new(term: "equality", concept_id: "102-01-01",
                                source: "urn:iec:std:iec:60050", ref_type: "urn")
      expect(ref.to_urn).to eq("urn:iec:std:iec:60050-102-01-01")
    end

    it "reconstructs ISO URN from source + concept_id" do
      ref = described_class.new(term: "lat", concept_id: "3.1.32",
                                source: "urn:iso:std:iso:19111", ref_type: "urn")
      expect(ref.to_urn).to eq("urn:iso:std:iso:19111:term:3.1.32")
    end

    it "returns nil for local references" do
      ref = described_class.new(term: "test", concept_id: "200",
                                ref_type: "local")
      expect(ref.to_urn).to be_nil
    end

    it "returns nil for designation references" do
      ref = described_class.new(term: "geodetic latitude",
                                ref_type: "designation")
      expect(ref.to_urn).to be_nil
    end

    it "returns nil when source is missing" do
      ref = described_class.new(term: "test", concept_id: "1", ref_type: "urn")
      expect(ref.to_urn).to be_nil
    end
  end

  describe "#to_gcr_hash" do
    it "produces flat hash with all fields for external reference" do
      ref = described_class.new(
        term: "equality",
        concept_id: "102-01-01",
        source: "urn:iec:std:iec:60050",
        ref_type: "urn",
      )

      expect(ref.to_gcr_hash).to eq({
                                      "term" => "equality",
                                      "concept_id" => "102-01-01",
                                      "source" => "urn:iec:std:iec:60050",
                                      "ref_type" => "urn",
                                    })
    end

    it "omits nil source for internal reference" do
      ref = described_class.new(
        term: "latitude",
        concept_id: "200",
        ref_type: "local",
      )

      expect(ref.to_gcr_hash).to eq({
                                      "term" => "latitude",
                                      "concept_id" => "200",
                                      "ref_type" => "local",
                                    })
    end

    it "omits nil concept_id for designation reference" do
      ref = described_class.new(
        term: "geodetic latitude",
        ref_type: "designation",
      )

      h = ref.to_gcr_hash
      expect(h["term"]).to eq("geodetic latitude")
      expect(h).not_to have_key("concept_id")
      expect(h["ref_type"]).to eq("designation")
    end
  end
end
