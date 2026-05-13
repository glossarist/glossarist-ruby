# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::RelatedConcept do
  # it_behaves_like "an Enum"

  subject { described_class.from_yaml(attributes) }
  let(:attributes) do
    {
      content: "Test content",
      type: :supersedes,
      ref: {
        source: "Test source",
        id: "Test id",
        version: "Test version",
      },
    }.to_yaml
  end

  describe "#to_yaml" do
    it "will convert related concept to yaml" do
      expected_yaml = <<~YAML
        ---
        content: Test content
        type: supersedes
        ref:
          source: Test source
          id: Test id
          version: Test version
      YAML

      expect(subject.to_yaml).to eq(expected_yaml)
    end
  end

  describe "relationship types" do
    Glossarist::GlossaryDefinition::RELATED_CONCEPT_TYPES.each do |rel_type|
      it "accepts #{rel_type} relationship type" do
        rc = described_class.new(type: rel_type, content: "test")
        expect(rc.type).to eq(rel_type)
      end
    end

    it "accepts close_match type" do
      rc = described_class.new(type: "close_match", content: "similar concept")
      expect(rc.type).to eq("close_match")
    end

    it "accepts broader_generic type (ISO 25964 BTG)" do
      rc = described_class.new(type: "broader_generic", content: "Vehicle")
      expect(rc.type).to eq("broader_generic")
    end

    it "accepts narrower_generic type (ISO 25964 NTG)" do
      rc = described_class.new(type: "narrower_generic", content: "Car")
      expect(rc.type).to eq("narrower_generic")
    end

    it "accepts broader_partitive type (ISO 25964 BTP)" do
      rc = described_class.new(type: "broader_partitive", content: "Engine")
      expect(rc.type).to eq("broader_partitive")
    end

    it "accepts narrower_partitive type (ISO 25964 NTP)" do
      rc = described_class.new(type: "narrower_partitive", content: "Piston")
      expect(rc.type).to eq("narrower_partitive")
    end

    it "accepts broader_instantial type (ISO 25964 BTI)" do
      rc = described_class.new(type: "broader_instantial", content: "Mammal")
      expect(rc.type).to eq("broader_instantial")
    end

    it "accepts narrower_instantial type (ISO 25964 NTI)" do
      rc = described_class.new(type: "narrower_instantial", content: "Fido")
      expect(rc.type).to eq("narrower_instantial")
    end

    it "accepts broad_match type (SKOS mapping)" do
      rc = described_class.new(type: "broad_match", content: "Vehicle (other vocab)")
      expect(rc.type).to eq("broad_match")
    end

    it "accepts narrow_match type (SKOS mapping)" do
      rc = described_class.new(type: "narrow_match", content: "Electric car (other vocab)")
      expect(rc.type).to eq("narrow_match")
    end

    it "accepts related_match type (SKOS mapping)" do
      rc = described_class.new(type: "related_match", content: "Automobile (other vocab)")
      expect(rc.type).to eq("related_match")
    end

    it "accepts related_concept type (TBX associative)" do
      rc = described_class.new(type: "related_concept", content: "school")
      expect(rc.type).to eq("related_concept")
    end

    it "accepts related_concept_broader type (TBX)" do
      rc = described_class.new(type: "related_concept_broader", content: "education")
      expect(rc.type).to eq("related_concept_broader")
    end

    it "accepts related_concept_narrower type (TBX)" do
      rc = described_class.new(type: "related_concept_narrower", content: "primary school")
      expect(rc.type).to eq("related_concept_narrower")
    end

    it "accepts sequentially_related_concept type (TBX)" do
      rc = described_class.new(type: "sequentially_related_concept", content: "next step")
      expect(rc.type).to eq("sequentially_related_concept")
    end

    it "accepts spatially_related_concept type (TBX)" do
      rc = described_class.new(type: "spatially_related_concept", content: "adjacent room")
      expect(rc.type).to eq("spatially_related_concept")
    end

    it "accepts temporally_related_concept type (TBX)" do
      rc = described_class.new(type: "temporally_related_concept", content: "preceding event")
      expect(rc.type).to eq("temporally_related_concept")
    end

    it "accepts homograph type" do
      rc = described_class.new(type: "homograph", content: "port (harbor)")
      expect(rc.type).to eq("homograph")
    end

    it "accepts false_friend type" do
      rc = described_class.new(type: "false_friend", content: "realize")
      expect(rc.type).to eq("false_friend")
    end
  end
end
