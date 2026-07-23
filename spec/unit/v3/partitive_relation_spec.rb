# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::PartitiveRelation do
  let(:comprehensive) { Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.1") }

  let(:partitives) do
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
    it "accepts comprehensive, partitives, completeness, plurality, criterion" do
      rel = described_class.new(
        comprehensive: comprehensive,
        partitives: partitives,
        completeness: "complete",
        plurality: Glossarist::V3::TypeSharedPlurality.new(is_shared: true),
        criterion: { "eng" => "physical structure" },
      )
      expect(rel.comprehensive.id).to eq("1.1")
      expect(rel.partitives.length).to eq(2)
      expect(rel.completeness).to eq("complete")
      expect(rel.plurality.is_shared).to be(true)
      expect(rel.criterion).to eq("eng" => "physical structure")
    end

    it "defaults completeness to complete when omitted" do
      rel = described_class.new(comprehensive: comprehensive, partitives: partitives)
      expect(rel.completeness).to eq("complete")
      expect(rel).to be_complete
      expect(rel).not_to be_partial
    end

    it "is coordinate when it has 2+ partitives" do
      rel = described_class.new(comprehensive: comprehensive, partitives: partitives)
      expect(rel).to be_coordinate
    end
  end

  describe "#validate!" do
    it "raises on empty comprehensive" do
      rel = described_class.new(
        comprehensive: Glossarist::V3::ConceptRef.new,
        partitives: partitives,
      )
      expect { rel.validate! }.to raise_error(ArgumentError, /comprehensive/)
    end

    it "raises on empty partitives" do
      rel = described_class.new(comprehensive: comprehensive, partitives: [])
      expect { rel.validate! }.to raise_error(ArgumentError, /at least one partitive/)
    end

    it "raises on single partitive (ISO 704 requires ≥2)" do
      rel = described_class.new(
        comprehensive: comprehensive,
        partitives: [partitives.first],
      )
      expect { rel.validate! }.to raise_error(ArgumentError, /≥2 partitives/)
    end

    it "raises on self-loop" do
      same = Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.1")
      rel = described_class.new(
        comprehensive: same,
        partitives: [
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
        partitives: partitives,
        completeness: "open",
      )
      expect { rel.validate! }.to raise_error(ArgumentError, /completeness/)
    end

    it "raises on incoherent plurality (is_uncertain without is_shared)" do
      rel = described_class.new(
        comprehensive: comprehensive,
        partitives: partitives,
        plurality: Glossarist::V3::TypeSharedPlurality.new(
          is_shared: false, is_uncertain: true,
        ),
      )
      expect { rel.validate! }
        .to raise_error(ArgumentError, /is_uncertain requires is_shared/)
    end
  end

  describe "round-trip YAML" do
    it "round-trips a complete relation with criterion" do
      rel = described_class.new(
        comprehensive: comprehensive,
        partitives: partitives,
        completeness: "complete",
        criterion: { "eng" => "physical structure" },
      )
      restored = described_class.from_yaml(rel.to_yaml).validate!
      expect(restored.comprehensive.id).to eq("1.1")
      expect(restored.partitives.map { |m| m.ref.id }).to eq(%w[1.2 1.3])
      expect(restored.completeness).to eq("complete")
      expect(restored.criterion).to eq("eng" => "physical structure")
    end

    it "round-trips a partial relation with plurality" do
      rel = described_class.new(
        comprehensive: comprehensive,
        partitives: partitives,
        completeness: "partial",
        plurality: Glossarist::V3::TypeSharedPlurality.new(
          is_shared: true, is_uncertain: true,
        ),
      )
      restored = described_class.from_yaml(rel.to_yaml).validate!
      expect(restored).to be_partial
      expect(restored.plurality.is_shared).to be(true)
      expect(restored.plurality.is_uncertain).to be(true)
    end
  end

  describe "integration with V3::ManagedConcept" do
    let(:mc_yaml) do
      <<~YAML
        ---
        identifier: '112-02-09'
        partitive_relations:
        - comprehensive:
            source: VIM
            id: '112-02-09'
          partitives:
          - ref:
              source: VIM
              id: '112-02-10'
          - ref:
              source: VIM
              id: '112-03-26'
          completeness: complete
          criterion:
            eng: measurement result composition
      YAML
    end

    it "round-trips partitive_relations at the concept level" do
      mc = Glossarist::V3::ManagedConcept.from_yaml(mc_yaml)
      rel_list = mc.partitive_relations
      expect(rel_list.length).to eq(1)
      expect(rel_list.first.comprehensive.id).to eq("112-02-09")
      expect(rel_list.first.partitives.map { |m| m.ref.id })
        .to eq(%w[112-02-10 112-03-26])
      expect(rel_list.first.completeness).to eq("complete")
      expect(rel_list.first.criterion).to eq("eng" => "measurement result composition")
    end
  end

  describe "schema_version detection" do
    it "detects V3 from partitive_relations alone" do
      mc = Glossarist::V3::ManagedConcept.new(
        data: Glossarist::V3::ManagedConceptData.new(id: "x"),
      )
      rel = described_class.new(
        comprehensive: comprehensive,
        partitives: partitives,
      ).validate!
      mc.partitive_relations = [rel]
      expect(Glossarist::ManagedConcept.detect_schema_version(mc)).to eq("3")
    end
  end
end
