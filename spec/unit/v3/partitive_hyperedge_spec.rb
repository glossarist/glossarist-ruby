# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::PartitiveHyperedge do
  let(:comprehensive) do
    Glossarist::V3::ConceptRef.new(source: "VIM", id: "2.9")
  end

  let(:parts) do
    [
      Glossarist::V3::ConceptRef.new(source: "VIM", id: "2.10"),
      Glossarist::V3::ConceptRef.new(source: "VIM", id: "2.26"),
    ]
  end

  describe "construction" do
    it "accepts comprehensive, parts, enumeration, markers, content" do
      he = described_class.new(
        comprehensive: comprehensive,
        parts: parts,
        enumeration: "closed",
        markers: ["double"],
        content: { "eng" => "value + uncertainty" },
      )

      expect(he.comprehensive.id).to eq("2.9")
      expect(he.parts.map(&:id)).to eq(%w[2.10 2.26])
      expect(he.enumeration).to eq("closed")
      expect(he.markers).to eq(["double"])
      expect(he.content).to eq("eng" => "value + uncertainty")
      expect(Glossarist::LocalizedString.fetch(he.content, "eng"))
        .to eq("value + uncertainty")
    end

    it "defaults enumeration to closed when omitted" do
      he = described_class.new(comprehensive: comprehensive, parts: parts)
      expect(he.enumeration).to eq("closed")
      expect(he.using_default?(:enumeration)).to be(true)
    end

    it "tracks explicit enumeration via using_default?" do
      he = described_class.new(comprehensive: comprehensive,
                               parts: parts, enumeration: "closed")
      expect(he.using_default?(:enumeration)).to be(false)
    end

    it "defaults markers to empty array when omitted" do
      he = described_class.new(comprehensive: comprehensive, parts: parts)
      expect(he.markers).to eq([])
    end
  end

  describe "#validate! (structural)" do
    it "passes for a fully-specified hyperedge" do
      he = described_class.new(
        comprehensive: comprehensive,
        parts: parts,
        enumeration: "closed",
        markers: ["double"],
      )
      expect { he.validate! }.not_to raise_error
    end

    it "raises on unknown enumeration values" do
      he = described_class.new(
        comprehensive: comprehensive,
        parts: parts,
        enumeration: "partial",
      )
      expect { he.validate! }.to raise_error(ArgumentError, /partial/)
    end

    it "raises on unknown marker values" do
      he = described_class.new(
        comprehensive: comprehensive,
        parts: parts,
        markers: ["dotted"],
      )
      expect { he.validate! }.to raise_error(ArgumentError, /dotted/)
    end

    it "raises on empty parts" do
      he = described_class.new(comprehensive: comprehensive, parts: [])
      expect { he.validate! }.to raise_error(ArgumentError, /at least one part/)
    end

    it "raises on empty comprehensive" do
      he = described_class.new(
        comprehensive: Glossarist::V3::ConceptRef.new,
        parts: parts,
      )
      expect { he.validate! }.to raise_error(ArgumentError, /comprehensive/)
    end

    it "raises on self-loop" do
      same = Glossarist::V3::ConceptRef.new(source: "VIM", id: "2.9")
      he = described_class.new(comprehensive: same, parts: [same])
      expect { he.validate! }.to raise_error(ArgumentError, /comprehensive/)
    end

    it "raises on default construction with no args" do
      he = described_class.new
      expect { he.validate! }.to raise_error(ArgumentError, /comprehensive/)
    end
  end

  describe "round-trip YAML" do
    it "round-trips a closed hyperedge with markers" do
      he = described_class.new(
        comprehensive: comprehensive,
        parts: parts,
        enumeration: "closed",
        markers: ["double"],
        content: { "eng" => "value + uncertainty" },
      )
      restored = described_class.from_yaml(he.to_yaml).validate!

      expect(restored.comprehensive.id).to eq("2.9")
      expect(restored.parts.map(&:id)).to eq(%w[2.10 2.26])
      expect(restored.enumeration).to eq("closed")
      expect(restored.markers).to eq(["double"])
      expect(restored.content).to eq("eng" => "value + uncertainty")
    end

    it "rejects invalid enumeration via YAML" do
      yaml = <<~YAML
        ---
        comprehensive:
          source: VIM
          id: '2.9'
        parts:
        - source: VIM
          id: '2.10'
        enumeration: partial
      YAML
      expect { described_class.from_yaml(yaml).validate! }
        .to raise_error(ArgumentError, /partial/)
    end

    it "round-trips an open hyperedge without markers" do
      he = described_class.new(
        comprehensive: comprehensive,
        parts: parts,
        enumeration: "open",
      )
      restored = described_class.from_yaml(he.to_yaml).validate!

      expect(restored.enumeration).to eq("open")
      expect(restored.markers).to eq([])
    end
  end

  describe "integration with V3::ManagedConceptData" do
    it "no longer carries partitive_hyperedges on ManagedConceptData" do
      mcd = Glossarist::V3::ManagedConceptData.new(id: "x")
      expect(mcd).not_to respond_to(:partitive_hyperedges)
    end
  end

  describe "integration with V3::ManagedConcept" do
    let(:mc_yaml) do
      <<~YAML
        ---
        identifier: '112-02-09'
        partitive_hyperedges:
        - comprehensive:
            source: VIM
            id: '112-02-09'
          parts:
          - source: VIM
            id: '112-02-10'
          - source: VIM
            id: '112-03-26'
          enumeration: closed
          markers:
          - double
      YAML
    end

    it "round-trips partitive_hyperedges at the concept level" do
      mc = Glossarist::V3::ManagedConcept.from_yaml(mc_yaml)
      he_list = mc.partitive_hyperedges
      expect(he_list.length).to eq(1)
      expect(he_list.first.comprehensive.id).to eq("112-02-09")
      expect(he_list.first.parts.map(&:id)).to eq(%w[112-02-10 112-03-26])
      expect(he_list.first.enumeration).to eq("closed")
      expect(he_list.first.markers).to eq(["double"])
    end
  end

  describe "configuration" do
    it "is reachable as a constant in the V3 namespace" do
      expect(described_class).to eq(Glossarist::V3::PartitiveHyperedge)
    end

    it "is registered in V3::Configuration as :partitive_hyperedge" do
      resolved = Glossarist::V3::Configuration.resolve_model(:partitive_hyperedge)
      expect(resolved).to eq(described_class)
    end

    it "no longer registers :partitive_enumeration or :plurality_marker" do
      expect {
        Glossarist::V3::Configuration.resolve_model(:partitive_enumeration)
      }.to raise_error(Lutaml::Model::UnknownTypeError)
      expect {
        Glossarist::V3::Configuration.resolve_model(:plurality_marker)
      }.to raise_error(Lutaml::Model::UnknownTypeError)
    end
  end

  describe "GlossaryDefinition SSOT" do
    it "loads partitive_enumeration values from config.yml" do
      expect(Glossarist::GlossaryDefinition::PARTITIVE_ENUMERATION_VALUES)
        .to eq(%w[closed open])
    end

    it "loads plurality_marker values from config.yml" do
      expect(Glossarist::GlossaryDefinition::PLURALITY_MARKER_VALUES)
        .to eq(%w[double dashed])
    end
  end

  describe "schema_version detection" do
    it "detects V3 from partitive_hyperedges alone" do
      mc = Glossarist::V3::ManagedConcept.new(
        data: Glossarist::V3::ManagedConceptData.new(id: "x"),
      )
      he = described_class.new(
        comprehensive: comprehensive,
        parts: [Glossarist::V3::ConceptRef.new(source: "VIM", id: "other")],
      ).validate!
      mc.partitive_hyperedges = [he]
      expect(Glossarist::ManagedConcept.detect_schema_version(mc)).to eq("3")
    end
  end
end
