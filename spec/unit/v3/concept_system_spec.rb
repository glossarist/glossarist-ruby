# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::ConceptSystem do
  let(:members) do
    [
      Glossarist::V3::ConceptRef.new(source: "VIML", id: "5.1"),
      Glossarist::V3::ConceptRef.new(source: "VIML", id: "5.13"),
      Glossarist::V3::ConceptRef.new(source: "VIML", id: "3.2"),
    ]
  end

  let(:valid_attrs) do
    {
      id: "viml-measurement-standard-system",
      name: { "eng" => "Measurement Standard System" },
      type: "mixed",
      members: members,
      hyperedges: ["viml-5-1/by-realization-medium"],
      root_concepts: [Glossarist::V3::ConceptRef.new(source: "VIML", id: "5.1")],
      status: "valid",
    }
  end

  describe "construction" do
    it "builds from a valid attribute hash" do
      cs = described_class.new(valid_attrs)
      expect(cs.id).to eq("viml-measurement-standard-system")
      expect(cs.name).to eq("eng" => "Measurement Standard System")
      expect(cs.type).to eq("mixed")
      expect(cs.members.length).to eq(3)
      expect(cs.hyperedges).to eq(["viml-5-1/by-realization-medium"])
    end

    it "defaults status to nil when omitted" do
      attrs = valid_attrs.dup
      attrs.delete(:status)
      cs = described_class.new(attrs)
      expect(cs.status).to be_nil
    end
  end

  describe "type predicates" do
    it "knows its type" do
      cs = described_class.new(valid_attrs)
      expect(cs).to be_mixed
      expect(cs).not_to be_generic

      cs_generic = described_class.new(valid_attrs.merge(type: "generic"))
      expect(cs_generic).to be_generic
    end
  end

  describe "#validate!" do
    it "passes for valid attributes" do
      cs = described_class.new(valid_attrs)
      expect { cs.validate! }.not_to raise_error
    end

    it "raises on empty id" do
      cs = described_class.new(valid_attrs.merge(id: nil))
      expect { cs.validate! }.to raise_error(ArgumentError, /id/)
    end

    it "raises on empty name" do
      cs = described_class.new(valid_attrs.merge(name: {}))
      expect { cs.validate! }.to raise_error(ArgumentError, /name/)
    end

    it "raises on invalid type" do
      cs = described_class.new(valid_attrs.merge(type: "unknown"))
      expect { cs.validate! }.to raise_error(ArgumentError, /type/)
    end

    it "raises on empty members" do
      cs = described_class.new(valid_attrs.merge(members: []))
      expect { cs.validate! }.to raise_error(ArgumentError, /members/)
    end
  end

  describe "ConceptSystemType constants" do
    it "exposes all 5 type values" do
      expect(Glossarist::V3::ConceptSystemType::VALUES).to eq(
        %w[generic partitive sequential associative mixed],
      )
    end
  end

  describe "EquivalenceDegree constants" do
    it "exposes all 4 equivalence values" do
      expect(Glossarist::V3::EquivalenceDegree::VALUES).to eq(
        %w[full partial none directional],
      )
    end
  end

  describe "ConceptType constants" do
    it "exposes general and individual" do
      expect(Glossarist::V3::ConceptType::VALUES).to eq(%w[general individual])
    end
  end
end
