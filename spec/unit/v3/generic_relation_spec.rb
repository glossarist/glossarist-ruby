# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::GenericHyperedge do
  let(:genus) { Glossarist::V3::ConceptRef.new(source: "VIML", id: "5.1") }

  let(:species) do
    [
      Glossarist::V3::GenericMember.new(
        ref: Glossarist::V3::ConceptRef.new(source: "VIML", id: "5.13"),
      ),
      Glossarist::V3::GenericMember.new(
        ref: Glossarist::V3::ConceptRef.new(source: "VIML", id: "3.2"),
      ),
      Glossarist::V3::GenericMember.new(
        ref: Glossarist::V3::ConceptRef.new(source: "VIML", id: "3.6"),
      ),
    ]
  end

  describe "construction" do
    it "accepts comprehensive (genus), members (species), criterion" do
      rel = described_class.new(
        comprehensive: genus,
        members: species,
        completeness: "complete",
        criterion: { "eng" => "by realization medium" },
      )
      expect(rel.comprehensive.id).to eq("5.1")
      expect(rel.members.length).to eq(3)
      expect(rel.completeness).to eq("complete")
      expect(rel.criterion).to eq("eng" => "by realization medium")
    end

    it "defaults completeness to complete when omitted" do
      rel = described_class.new(comprehensive: genus, members: species)
      expect(rel.completeness).to eq("complete")
    end

    it "is coordinate when it has 2+ members" do
      rel = described_class.new(comprehensive: genus, members: species)
      expect(rel).to be_coordinate
    end
  end

  describe "#validate!" do
    it "raises on empty comprehensive" do
      rel = described_class.new(
        comprehensive: Glossarist::V3::ConceptRef.new,
        members: species,
      )
      expect { rel.validate! }.to raise_error(ArgumentError, /comprehensive/)
    end

    it "raises on single member (ISO 704 requires >=2)" do
      rel = described_class.new(
        comprehensive: genus,
        members: [species.first],
      )
      expect { rel.validate! }.to raise_error(ArgumentError, />=2.*members/)
    end
  end

  describe "round-trip YAML" do
    it "round-trips a complete relation with criterion" do
      rel = described_class.new(
        comprehensive: genus,
        members: species,
        completeness: "complete",
        criterion: { "eng" => "by realization medium" },
      )
      restored = described_class.from_yaml(rel.to_yaml).validate!
      expect(restored.comprehensive.id).to eq("5.1")
      expect(restored.members.map { |m| m.ref.id }).to eq(%w[5.13 3.2 3.6])
      expect(restored.criterion).to eq("eng" => "by realization medium")
    end
  end

  describe "standalone relation file format" do
    let(:file_yaml) do
      <<~YAML
        ---
        $id: viml-5-1/by-realization-medium
        type: generic_relation
        comprehensive:
          source: VIML
          id: '5.1'
        members:
        - ref:
            source: VIML
            id: '5.13'
        - ref:
            source: VIML
            id: '3.2'
        completeness: complete
        criterion:
          eng: by realization medium
      YAML
    end

    it "round-trips the per-file wire format" do
      rel = described_class.from_yaml(file_yaml)
      expect(rel.comprehensive.id).to eq("5.1")
      expect(rel.members.map { |m| m.ref.id }).to eq(%w[5.13 3.2])
    end
  end
end
