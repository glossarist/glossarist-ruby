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

    it "builds with direct urn" do
      ref = described_class.new(
        term: "test",
        urn: "urn:iec:std:iec:60050-102-102-04-22",
        ref_type: "urn",
      )
      expect(ref.urn).to eq("urn:iec:std:iec:60050-102-102-04-22")
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

    it "handles urn field" do
      ref = described_class.new(
        term: "test",
        urn: "urn:iec:std:iec:60050-102-102-04-22",
        ref_type: "urn",
      )

      yaml = ref.to_yaml
      loaded = described_class.from_yaml(yaml)

      expect(loaded.urn).to eq("urn:iec:std:iec:60050-102-102-04-22")
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
end
