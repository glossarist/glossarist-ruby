# frozen_string_literal: true

require "spec_helper"
require "glossarist/v2"
require "glossarist/v3"

RSpec.describe "V2/V3 namespace architecture" do
  describe "Model register (lutaml-model GlobalContext)" do
    describe Glossarist::V2::Configuration do
      it "resolves :managed_concept to V2::ManagedConcept" do
        expect(described_class.resolve_model(:managed_concept)).to eq(
          Glossarist::V2::ManagedConcept,
        )
      end

      it "resolves :managed_concept_data to V2::ManagedConceptData" do
        expect(described_class.resolve_model(:managed_concept_data)).to eq(
          Glossarist::V2::ManagedConceptData,
        )
      end

      it "resolves :concept_document to V2::ConceptDocument" do
        expect(described_class.resolve_model(:concept_document)).to eq(
          Glossarist::V2::ConceptDocument,
        )
      end

      it "has context_id :glossarist_v2" do
        expect(described_class.context_id).to eq(:glossarist_v2)
      end
    end

    describe Glossarist::V3::Configuration do
      it "resolves :managed_concept to V3::ManagedConcept" do
        expect(described_class.resolve_model(:managed_concept)).to eq(
          Glossarist::V3::ManagedConcept,
        )
      end

      it "resolves :managed_concept_data to V3::ManagedConceptData" do
        expect(described_class.resolve_model(:managed_concept_data)).to eq(
          Glossarist::V3::ManagedConceptData,
        )
      end

      it "resolves :concept_document to V3::ConceptDocument" do
        expect(described_class.resolve_model(:concept_document)).to eq(
          Glossarist::V3::ConceptDocument,
        )
      end

      it "has context_id :glossarist_v3" do
        expect(described_class.context_id).to eq(:glossarist_v3)
      end
    end

    it "v2 and v3 resolve :managed_concept to different classes" do
      v2_mc = Glossarist::V2::Configuration.resolve_model(:managed_concept)
      v3_mc = Glossarist::V3::Configuration.resolve_model(:managed_concept)
      expect(v2_mc).not_to eq(v3_mc)
    end
  end

  describe Glossarist::ConceptDocument, ".for_version" do
    it "resolves V2::ConceptDocument via context registry" do
      expect(described_class.for_version("2")).to eq(Glossarist::V2::ConceptDocument)
    end

    it "resolves V3::ConceptDocument via context registry" do
      expect(described_class.for_version("3")).to eq(Glossarist::V3::ConceptDocument)
    end

    it "defaults to V3 for unknown version" do
      expect(described_class.for_version("99")).to eq(Glossarist::V3::ConceptDocument)
    end
  end

  describe Glossarist::V2::ManagedConceptData do
    it "inherits from Glossarist::ManagedConceptData" do
      expect(described_class).to be < Glossarist::ManagedConceptData
    end

    it "deserializes related inside data" do
      yaml = {
        "identifier" => "test-1",
        "localized_concepts" => { "eng" => "l10n-uuid" },
        "related" => [
          { "type" => "broader", "content" => "Parent concept" },
          { "type" => "narrower", "content" => "Child concept" },
        ],
      }
      mcd = described_class.of_yaml(yaml)
      expect(mcd.related.length).to eq(2)
      expect(mcd.related[0].type).to eq("broader")
      expect(mcd.related[1].type).to eq("narrower")
    end

    it "serializes related inside data" do
      mcd = described_class.new
      mcd.id = "test-1"
      mcd.related = [
        Glossarist::RelatedConcept.new(type: "broader", content: "Parent"),
      ]
      hash = mcd.to_hash
      expect(hash).to have_key("related")
      expect(hash["related"].length).to eq(1)
    end
  end

  describe Glossarist::V3::ManagedConceptData do
    it "inherits from Glossarist::ManagedConceptData" do
      expect(described_class).to be < Glossarist::ManagedConceptData
    end

    it "maps related in key_value" do
      mcd = described_class.new
      mcd.id = "test-1"
      mcd.related = [
        Glossarist::V3::RelatedConcept.new(type: "broader", content: "Parent"),
      ]
      hash = mcd.to_hash
      expect(hash).to have_key("related")
    end
  end

  describe Glossarist::V2::ManagedConcept do
    it "inherits from Glossarist::ManagedConcept" do
      expect(described_class).to be < Glossarist::ManagedConcept
    end

    it "uses V2::ManagedConceptData for data attribute" do
      mc = described_class.new
      expect(mc.data).to be_a(Glossarist::V2::ManagedConceptData)
    end

    it "deserializes v2 YAML with related inside data" do
      yaml = {
        "data" => {
          "identifier" => "test-1",
          "localized_concepts" => { "eng" => "l10n-uuid" },
          "related" => [
            { "type" => "broader", "content" => "Parent" },
          ],
        },
        "id" => "concept-uuid",
      }
      mc = described_class.of_yaml(yaml)
      expect(mc.data.related.length).to eq(1)
      expect(mc.data.related[0].type).to eq("broader")
    end

    it "inherits v3 serialization from base class" do
      mc = described_class.new
      mc.data.id = "test-1"
      mc.related = [Glossarist::V2::RelatedConcept.new(type: "broader")]
      mc.schema_version = "3"
      hash = mc.to_hash
      expect(hash).to have_key("related")
      expect(hash).to have_key("schema_version")
    end
  end

  describe Glossarist::V3::ManagedConcept do
    it "inherits from Glossarist::ManagedConcept" do
      expect(described_class).to be < Glossarist::ManagedConcept
    end

    it "uses V3::ManagedConceptData for data attribute" do
      mc = described_class.new
      expect(mc.data).to be_a(Glossarist::V3::ManagedConceptData)
    end

    it "deserializes v3 YAML with related at top level" do
      yaml = {
        "data" => {
          "identifier" => "test-1",
          "localized_concepts" => { "eng" => "l10n-uuid" },
        },
        "related" => [
          { "type" => "broader", "content" => "Parent" },
        ],
        "schema_version" => "3",
        "id" => "concept-uuid",
      }
      mc = described_class.of_yaml(yaml)
      expect(mc.related.length).to eq(1)
      expect(mc.related[0].type).to eq("broader")
    end

    it "serializes related at top level" do
      mc = described_class.new
      mc.data.id = "test-1"
      mc.related = [Glossarist::V3::RelatedConcept.new(type: "broader")]
      hash = mc.to_hash
      expect(hash).to have_key("related")
      expect(hash["related"].length).to eq(1)
    end

    it "serializes schema_version" do
      mc = described_class.new
      mc.data.id = "test-1"
      mc.schema_version = "3"
      hash = mc.to_hash
      expect(hash["schema_version"]).to eq("3")
    end
  end

  describe Glossarist::V2::ConceptDocument do
    it "uses V2::ManagedConcept in yamls mapping" do
      v2_yaml = {
        "data" => {
          "identifier" => "test-1",
          "localized_concepts" => { "eng" => "l10n-uuid" },
          "related" => [{ "type" => "broader" }],
        },
        "id" => "concept-uuid",
      }.to_yaml

      doc = described_class.from_yamls(v2_yaml)
      expect(doc.concept).to be_a(Glossarist::V2::ManagedConcept)
    end
  end

  describe Glossarist::V3::ConceptDocument do
    it "uses V3::ManagedConcept in yamls mapping" do
      v3_yaml = {
        "data" => {
          "identifier" => "test-1",
          "localized_concepts" => { "eng" => "l10n-uuid" },
        },
        "related" => [{ "type" => "broader" }],
        "schema_version" => "3",
        "id" => "concept-uuid",
      }.to_yaml

      doc = described_class.from_yamls(v3_yaml)
      expect(doc.concept).to be_a(Glossarist::V3::ManagedConcept)
    end
  end

  describe "v2 → v3 model-driven migration" do
    it "promotes data.related to concept.related" do
      v2_yaml = {
        "data" => {
          "identifier" => "test-1",
          "localized_concepts" => { "eng" => "l10n-uuid" },
          "related" => [
            { "type" => "broader", "content" => "Parent" },
            { "type" => "narrower", "content" => "Child" },
          ],
        },
        "id" => "concept-uuid",
      }.to_yaml

      doc = Glossarist::V2::ConceptDocument.from_yamls(v2_yaml)
      concept = doc.concept

      expect(concept.data.related.length).to eq(2)
      expect(concept.related).to be_nil.or be_empty

      Glossarist::SchemaMigration.migrate_concept(concept)

      expect(concept.related.length).to eq(2)
      expect(concept.related[0].type).to eq("broader")
      expect(concept.related[1].type).to eq("narrower")
      expect(concept.schema_version).to eq("3")
    end

    it "serializes migrated concept as v3" do
      v2_yaml = {
        "data" => {
          "identifier" => "test-1",
          "localized_concepts" => { "eng" => "l10n-uuid" },
          "related" => [
            { "type" => "broader", "content" => "Parent" },
          ],
        },
        "id" => "concept-uuid",
      }.to_yaml

      doc = Glossarist::V2::ConceptDocument.from_yamls(v2_yaml)
      concept = doc.concept
      Glossarist::SchemaMigration.migrate_concept(concept)

      yaml_output = concept.to_yaml
      parsed = YAML.safe_load(yaml_output, permitted_classes: [Date, Time])

      expect(parsed["related"]).not_to be_nil
      expect(parsed["related"].length).to eq(1)
      expect(parsed["schema_version"]).to eq("3")
    end
  end
end
