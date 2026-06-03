# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Tags attribute" do
  describe Glossarist::ManagedConceptData do
    describe "tags attribute" do
      it "accepts an array of strings" do
        data = described_class.new(tags: ["general", "time-scale-units"])
        expect(data.tags).to eq(["general", "time-scale-units"])
      end

      it "round-trips through YAML" do
        data = described_class.new(tags: ["general",
                                          "expressions-and-representations"])
        yaml = data.to_yaml
        restored = described_class.from_yaml(yaml)
        expect(restored.tags).to eq(["general",
                                     "expressions-and-representations"])
      end

      it "round-trips through hash" do
        data = described_class.new(tags: ["general"])
        hash = data.to_hash
        restored = described_class.from_hash(hash)
        expect(restored.tags).to eq(["general"])
      end

      it "omits tags when nil" do
        data = described_class.new
        yaml = data.to_yaml
        expect(yaml).not_to include("tags")
      end

      it "round-trips empty array as nil (lutaml-model omits empty collections)" do
        data = described_class.new(tags: [])
        yaml = data.to_yaml
        expect(yaml).not_to include("tags")
        restored = described_class.from_yaml(yaml)
        expect(restored.tags).to be_nil
      end
    end
  end

  describe Glossarist::ManagedConcept do
    it "sets and reads tags through data attribute" do
      concept = described_class.new(
        identifier: "3.6.1",
        status: "valid",
        data: { tags: ["general"] },
      )
      expect(concept.data.tags).to eq(["general"])
    end

    it "round-trips tags through full concept YAML" do
      concept = described_class.new(
        identifier: "3.6.1",
        status: "valid",
        data: {
          id: "3.6.1",
          tags: ["general", "time-scale-units"],
          domains: [{ concept_id: "103", ref_type: "domain" }],
        },
      )
      yaml = concept.to_yaml
      restored = described_class.from_yaml(yaml)
      expect(restored.data.tags).to eq(["general", "time-scale-units"])
      expect(restored.data.domains.map(&:concept_id)).to eq(["103"])
    end

    it "round-trips tags through hash" do
      concept = described_class.new(
        identifier: "3.6.1",
        status: "valid",
        data: { id: "3.6.1", tags: ["general"] },
      )
      hash = concept.to_hash
      restored = described_class.from_hash(hash)
      expect(restored.data.tags).to eq(["general"])
    end

    it "preserves tags alongside domains and sources" do
      concept = described_class.new(
        identifier: "7.10",
        status: "valid",
        data: {
          id: "7.10",
          tags: ["time-scale-units"],
          domains: [{ concept_id: "103", ref_type: "domain" }],
          sources: [{ type: "authoritative",
                      origin: { ref: { source: "ISO", id: "34000" } } }],
        },
      )
      yaml = concept.to_yaml
      restored = described_class.from_yaml(yaml)
      expect(restored.data.tags).to eq(["time-scale-units"])
      expect(restored.data.domains.map(&:concept_id)).to eq(["103"])
      expect(restored.data.sources.first.type).to eq("authoritative")
    end
  end

  describe Glossarist::V3::ManagedConceptData do
    it "inherits tags attribute from parent" do
      data = described_class.new(tags: ["general"])
      expect(data.tags).to eq(["general"])
    end

    it "round-trips tags through YAML" do
      data = described_class.new(tags: ["expressions-and-representations"])
      yaml = data.to_yaml
      restored = described_class.from_yaml(yaml)
      expect(restored.tags).to eq(["expressions-and-representations"])
    end
  end

  describe Glossarist::V3::ManagedConcept do
    it "round-trips tags through v3 concept YAML" do
      concept = described_class.new(
        identifier: "3.6.1",
        status: "valid",
        data: {
          id: "3.6.1",
          tags: ["general"],
          localized_concepts: { "eng" => "l10n-uuid" },
        },
        related: [{ type: "broader", content: "Parent" }],
        schema_version: "3",
      )
      yaml = concept.to_yaml
      restored = described_class.from_yaml(yaml)
      expect(restored.data.tags).to eq(["general"])
      expect(restored.related.first.type).to eq("broader")
    end
  end

  describe "ConceptDocument loading path" do
    fixtures_dir = File.join(File.dirname(__FILE__), "..", "fixtures",
                             "concept-model-examples")

    it "preserves tags through V3 ConceptDocument.from_yamls (ConceptManager path)" do
      path = File.join(fixtures_dir, "v3", "16-tags.yaml")
      raw = File.read(path)
      doc = Glossarist::V3::ConceptDocument.from_yamls(raw)
      concept = doc.concept

      expect(concept.data.tags).to eq(%w[general time-scale-units])
      expect(concept.data.domains.map(&:concept_id)).to eq(["103"])
    end

    it "preserves tags through V2 ConceptDocument.from_yamls (ConceptManager path)" do
      path = File.join(fixtures_dir, "v2", "16-tags.yaml")
      raw = File.read(path)
      doc = Glossarist::V2::ConceptDocument.from_yamls(raw)
      concept = doc.concept

      expect(concept.data.tags).to eq(%w[general time-scale-units])
      expect(concept.data.domains.map(&:concept_id)).to eq(["103"])
    end
  end

  describe "fixture round-trip" do
    fixtures_dir = File.join(File.dirname(__FILE__), "..", "fixtures",
                             "concept-model-examples")

    it "round-trips v2 tags fixture" do
      path = File.join(fixtures_dir, "v2", "16-tags.yaml")
      raw = File.read(path)
      concept = Glossarist::ManagedConcept.from_yaml(raw)
      expect(concept.data.tags).to eq(%w[general time-scale-units])
      expect(concept.data.domains.map(&:concept_id)).to eq(["103"])

      yaml = concept.to_yaml
      restored = Glossarist::ManagedConcept.from_yaml(yaml)
      expect(restored.data.tags).to eq(%w[general time-scale-units])
    end

    it "round-trips v3 tags fixture" do
      path = File.join(fixtures_dir, "v3", "16-tags.yaml")
      raw = File.read(path)
      concept = Glossarist::ManagedConcept.from_yaml(raw)
      expect(concept.data.tags).to eq(%w[general time-scale-units])
      expect(concept.data.domains.map(&:concept_id)).to eq(["103"])

      yaml = concept.to_yaml
      restored = Glossarist::ManagedConcept.from_yaml(yaml)
      expect(restored.data.tags).to eq(%w[general time-scale-units])
    end
  end
end
