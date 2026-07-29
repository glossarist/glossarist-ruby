# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::PartitiveRelation do
  let(:comprehensive) { Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.1") }

  let(:members) do
    [
      Glossarist::V3::PartitiveMember.new(
        ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2"),
      ),
      Glossarist::V3::PartitiveMember.new(
        ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.3"),
      ),
    ]
  end

  describe "construction" do
    it "accepts comprehensive, members, completeness, criterion" do
      rel = described_class.new(
        comprehensive: comprehensive,
        members: members,
        completeness: "complete",
        criterion: { "eng" => "physical structure" },
      )
      expect(rel.comprehensive.id).to eq("1.1")
      expect(rel.members.length).to eq(2)
      expect(rel.completeness).to eq("complete")
      expect(rel.criterion).to eq("eng" => "physical structure")
    end

    it "defaults completeness to complete when omitted" do
      rel = described_class.new(comprehensive: comprehensive, members: members)
      expect(rel.completeness).to eq("complete")
      expect(rel).to be_complete
      expect(rel).not_to be_partial
    end

    it "is coordinate when it has 2+ members" do
      rel = described_class.new(comprehensive: comprehensive, members: members)
      expect(rel).to be_coordinate
    end
  end

  describe "#validate!" do
    it "raises on empty comprehensive" do
      rel = described_class.new(
        comprehensive: Glossarist::V3::ConceptRef.new,
        members: members,
      )
      expect { rel.validate! }.to raise_error(ArgumentError, /comprehensive/)
    end

    it "raises on empty members" do
      rel = described_class.new(comprehensive: comprehensive, members: [])
      expect { rel.validate! }.to raise_error(ArgumentError, /at least one.*member/)
    end

    it "raises on single member (ISO 704 requires ≥2)" do
      rel = described_class.new(
        comprehensive: comprehensive,
        members: [members.first],
      )
      expect { rel.validate! }.to raise_error(ArgumentError, />=2.*members/)
    end

    it "raises on self-loop" do
      same = Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.1")
      rel = described_class.new(
        comprehensive: same,
        members: [
          Glossarist::V3::PartitiveMember.new(ref: same),
          Glossarist::V3::PartitiveMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2"),
          ),
        ],
      )
      expect { rel.validate! }.to raise_error(ArgumentError, /comprehensive/)
    end

    it "raises on invalid completeness" do
      rel = described_class.new(
        comprehensive: comprehensive,
        members: members,
        completeness: "open",
      )
      expect { rel.validate! }.to raise_error(ArgumentError, /completeness/)
    end
  end

  describe "round-trip YAML" do
    it "round-trips a complete relation with criterion" do
      rel = described_class.new(
        comprehensive: comprehensive,
        members: members,
        completeness: "complete",
        criterion: { "eng" => "physical structure" },
      )
      restored = described_class.from_yaml(rel.to_yaml).validate!
      expect(restored.comprehensive.id).to eq("1.1")
      expect(restored.members.map { |m| m.ref.id }).to eq(%w[1.2 1.3])
      expect(restored.completeness).to eq("complete")
      expect(restored.criterion).to eq("eng" => "physical structure")
    end

    it "round-trips a partial relation with mixed multiplicity members" do
      mixed = [
        Glossarist::V3::PartitiveMember.new(
          ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2"),
          presence: "required", count: "exactly_one",
          is_delimiting: true
        ),
        Glossarist::V3::PartitiveMember.new(
          ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.3"),
          presence: "optional", count: "exactly_one"
        ),
      ]
      rel = described_class.new(
        comprehensive: comprehensive,
        members: mixed,
        completeness: "partial",
      )
      restored = described_class.from_yaml(rel.to_yaml).validate!
      expect(restored).to be_partial
      expect(restored.members.first).to be_delimiting
      expect(restored.members.first).to be_required
      expect(restored.members.last).to be_optional
    end
  end

  describe "standalone relation file format" do
    let(:file_yaml) do
      <<~YAML
        ---
        $id: vim-1-1/physical-structure
        type: partitive_relation
        comprehensive:
          source: VIM
          id: '1.1'
        members:
        - ref:
            source: VIM
            id: '1.2'
        - ref:
            source: VIM
            id: '1.3'
        completeness: complete
        criterion:
          eng: physical structure
      YAML
    end

    it "round-trips the per-file wire format" do
      rel = described_class.from_yaml(file_yaml)
      expect(rel.comprehensive.id).to eq("1.1")
      expect(rel.members.map { |m| m.ref.id }).to eq(%w[1.2 1.3])
      expect(rel.completeness).to eq("complete")
      expect(rel.criterion).to eq("eng" => "physical structure")
    end
  end
end
