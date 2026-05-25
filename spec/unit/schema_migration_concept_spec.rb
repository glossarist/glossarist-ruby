# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::SchemaMigration, ".migrate_concept" do
  let(:v2_concept) do
    mc = Glossarist::ManagedConcept.new
    mc.data.id = "test-1"
    mc.data.localized_concepts = { "eng" => "l10n-uuid" }
    mc.data.related = [
      Glossarist::RelatedConcept.new(type: "broader", content: "Parent"),
      Glossarist::RelatedConcept.new(type: "narrower", content: "Child"),
    ]
    mc
  end

  describe "step v2 → v3" do
    it "moves data.related to concept.related" do
      result = described_class.migrate_concept(v2_concept, target_version: "3")

      expect(result.related.length).to eq(2)
      expect(result.related[0].type).to eq("broader")
      expect(result.related[1].type).to eq("narrower")
      expect(result.data.related).to be_empty
    end

    it "merges with existing concept.related and deduplicates" do
      existing = Glossarist::RelatedConcept.new(type: "compare", content: "Other")
      v2_concept.related = [existing]
      v2_concept.schema_version = "2"

      result = described_class.migrate_concept(v2_concept, target_version: "3")

      expect(result.related.length).to eq(3)
      expect(result.related.map(&:type)).to contain_exactly("compare", "broader", "narrower")
    end

    it "is a no-op when data.related is empty" do
      v2_concept.data.related = []
      v2_concept.schema_version = "2"

      result = described_class.migrate_concept(v2_concept, target_version: "3")

      expect(result.related).to be_nil
    end
  end

  describe "version handling" do
    it "sets schema_version on the concept" do
      result = described_class.migrate_concept(v2_concept, target_version: "3")
      expect(result.schema_version).to eq("3")
    end

    it "returns the same concept object" do
      result = described_class.migrate_concept(v2_concept, target_version: "3")
      expect(result).to equal(v2_concept)
    end

    it "is a no-op when already at target version" do
      v2_concept.schema_version = "3"

      result = described_class.migrate_concept(v2_concept, target_version: "3")

      expect(result.schema_version).to eq("3")
    end

    it "detects version from concept when schema_version is nil" do
      v2_concept.schema_version = nil

      result = described_class.migrate_concept(v2_concept, target_version: "3")

      expect(result.schema_version).to eq("3")
    end

    it "raises on unsupported migration path" do
      v2_concept.schema_version = "99"

      expect do
        described_class.migrate_concept(v2_concept, target_version: "100")
      end.to raise_error(Glossarist::Error, /No concept migration step/)
    end
  end

  describe "serialization round-trip" do
    it "serializes migrated concept as v3" do
      described_class.migrate_concept(v2_concept, target_version: "3")

      yaml_output = v2_concept.to_yaml
      parsed = YAML.safe_load(yaml_output, permitted_classes: [Date, Time])

      expect(parsed["related"]).not_to be_nil
      expect(parsed["related"].length).to eq(2)
      expect(parsed["schema_version"]).to eq("3")
    end
  end
end

RSpec.describe Glossarist::SchemaMigration, ".concept_version" do
  it "returns explicit schema_version when set" do
    mc = Glossarist::ManagedConcept.new
    mc.schema_version = "3"
    expect(described_class.concept_version(mc)).to eq("3")
  end

  it "delegates to detect_schema_version when nil" do
    mc = Glossarist::ManagedConcept.new
    mc.schema_version = nil
    mc.data.id = "test"

    expect(Glossarist::ManagedConcept).to receive(:detect_schema_version).and_return("2")
    expect(described_class.concept_version(mc)).to eq("2")
  end
end

RSpec.describe Glossarist::ManagedConcept, ".detect_schema_version" do
  it "returns explicit schema_version" do
    mc = Glossarist::ManagedConcept.new
    mc.schema_version = "3"
    expect(described_class.detect_schema_version(mc)).to eq("3")
  end

  it "returns '3' when concept has related" do
    mc = Glossarist::ManagedConcept.new
    mc.related = [Glossarist::RelatedConcept.new(type: "broader")]
    expect(described_class.detect_schema_version(mc)).to eq("3")
  end

  it "returns '3' when concept has sources" do
    mc = Glossarist::ManagedConcept.new
    mc.sources = [Glossarist::ConceptSource.new(type: "authoritative")]
    expect(described_class.detect_schema_version(mc)).to eq("3")
  end

  it "returns '3' when concept has domains" do
    mc = Glossarist::ManagedConcept.new
    mc.data.domains = [Glossarist::ConceptReference.new(concept_id: "103-01")]
    expect(described_class.detect_schema_version(mc)).to eq("3")
  end

  it "returns '2' for plain v2 concept" do
    mc = Glossarist::ManagedConcept.new
    mc.data.id = "test-1"
    expect(described_class.detect_schema_version(mc)).to eq("2")
  end
end
