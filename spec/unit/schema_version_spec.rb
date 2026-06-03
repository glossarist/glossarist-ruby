# frozen_string_literal: true

RSpec.describe Glossarist::ManagedConcept, "schema versioning" do
  describe "schema_version attribute" do
    it "defaults to current schema version" do
      mc = described_class.new
      expect(mc.schema_version).to be_nil
    end

    it "serializes to YAML with schema_version" do
      mc = described_class.of_yaml({ "data" => { "id" => "test" } })
      mc.schema_version = "3"
      yaml = mc.to_yaml
      parsed = YAML.safe_load(yaml)
      expect(parsed["schema_version"]).to eq("3")
    end

    it "round-trips schema_version through YAML" do
      mc = described_class.of_yaml({
                                     "data" => { "id" => "test" },
                                     "schema_version" => "2",
                                   })
      expect(mc.schema_version).to eq("2")

      round_tripped = described_class.from_yaml(mc.to_yaml)
      expect(round_tripped.schema_version).to eq("2")
    end
  end

  describe "#schema_version" do
    it "returns '2' when set to '2'" do
      mc = described_class.new
      mc.schema_version = "2"
      expect(mc.schema_version).to eq("2")
    end

    it "returns nil when not set" do
      mc = described_class.new
      expect(mc.schema_version).to be_nil
    end
  end

  describe "#uuid stability" do
    it "produces same UUID regardless of schema_version" do
      mc_v2 = described_class.of_yaml({
                                        "data" => { "id" => "test" },
                                        "schema_version" => "2",
                                      })
      mc_v3 = described_class.of_yaml({
                                        "data" => { "id" => "test" },
                                        "schema_version" => "3",
                                      })
      expect(mc_v2.uuid).to eq(mc_v3.uuid)
    end
  end

  describe ".detect_schema_version" do
    it "returns existing schema_version when present and not legacy" do
      mc = described_class.of_yaml({
                                     "data" => { "id" => "test" },
                                     "schema_version" => "2",
                                   })
      expect(described_class.detect_schema_version(mc)).to eq("2")
    end

    it "detects v3 from top-level related concepts" do
      mc = described_class.of_yaml({
                                     "data" => { "id" => "test" },
                                     "related" => [{ "type" => "broader",
                                                     "content" => "Parent" }],
                                   })
      expect(described_class.detect_schema_version(mc)).to eq("3")
    end

    it "detects v3 from top-level sources" do
      mc = described_class.of_yaml({
                                     "data" => { "id" => "test" },
                                     "sources" => [{ "type" => "authoritative" }],
                                   })
      expect(described_class.detect_schema_version(mc)).to eq("3")
    end

    it "detects v3 from data.domains" do
      mc = described_class.of_yaml({
                                     "data" => {
                                       "id" => "test",
                                       "domains" => [{ "concept_id" => "103",
                                                       "ref_type" => "domain" }],
                                     },
                                   })
      expect(described_class.detect_schema_version(mc)).to eq("3")
    end

    it "defaults to v2 for minimal concepts" do
      mc = described_class.of_yaml({ "data" => { "id" => "test" } })
      expect(described_class.detect_schema_version(mc)).to eq("2")
    end
  end

  describe ".localization_has_references?" do
    it "returns true when a localization has references" do
      mc = described_class.of_yaml({ "data" => { "id" => "test" } })
      l10n = Glossarist::LocalizedConcept.of_yaml({
                                                    "data" => {
                                                      "language_code" => "eng",
                                                      "references" => [{
                                                        "source" => "urn:iec:std:iec:60050", "ref_type" => "urn"
                                                      }],
                                                    },
                                                  })
      mc.add_l10n(l10n)
      expect(described_class.localization_has_references?(mc)).to be true
    end

    it "returns false when no localizations have references" do
      mc = described_class.of_yaml({ "data" => { "id" => "test" } })
      l10n = Glossarist::LocalizedConcept.of_yaml({
                                                    "data" => { "language_code" => "eng" },
                                                  })
      mc.add_l10n(l10n)
      expect(described_class.localization_has_references?(mc)).to be false
    end
  end

  describe "#assign_uuid" do
    it "sets the UUID without triggering computation" do
      mc = described_class.new
      mc.assign_uuid("test-uuid-123")
      expect(mc.uuid).to eq("test-uuid-123")
    end
  end
end

RSpec.describe Glossarist::SchemaMigration, "model-driven migration" do
  describe ".migrate_concept" do
    it "sets schema_version to current version" do
      mc = Glossarist::ManagedConcept.of_yaml({ "data" => { "id" => "test" } })
      mc.schema_version = "2"
      described_class.migrate_concept(mc)
      expect(mc.schema_version).to eq("3")
    end

    it "accepts a target version and migrates when needed" do
      mc = Glossarist::ManagedConcept.of_yaml({ "data" => { "id" => "test" } })
      mc.schema_version = "2"
      described_class.migrate_concept(mc, target_version: "3")
      expect(mc.schema_version).to eq("3")
    end

    it "is a no-op when already at target version" do
      mc = Glossarist::ManagedConcept.of_yaml({ "data" => { "id" => "test" } })
      mc.schema_version = "3"
      described_class.migrate_concept(mc, target_version: "3")
      expect(mc.schema_version).to eq("3")
    end

    it "returns the concept" do
      mc = Glossarist::ManagedConcept.of_yaml({ "data" => { "id" => "test" } })
      result = described_class.migrate_concept(mc)
      expect(result).to equal(mc)
    end
  end
end

RSpec.describe Glossarist::GcrMetadata, "schema_version" do
  it "defaults to current schema version" do
    metadata = described_class.new
    expect(metadata.schema_version).to eq(Glossarist::SCHEMA_VERSION)
  end

  it "uses schema version from register data when present" do
    concepts = [
      Glossarist::ManagedConcept.of_yaml({ "data" => { "id" => "1" } }),
    ]
    rd = Glossarist::RegisterData.from_yaml({ "shortname" => "test",
                                              "schema_version" => "2" }.to_yaml)
    metadata = described_class.from_concepts(concepts, register_data: rd)
    expect(metadata.schema_version).to eq("2")
  end
end
