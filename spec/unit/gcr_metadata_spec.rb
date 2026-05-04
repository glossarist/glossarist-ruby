# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::GcrMetadata do
  describe ".from_concepts" do
    let(:concepts) do
      mc1 = Glossarist::ManagedConcept.new(data: { id: "1" })
      mc1.add_localization(build_l10n("eng",
                                      definition: [{ "content" => "def" }],
                                      entry_status: "valid",
                                      sources: [{ "type" => "authoritative" }]))
      mc1.add_localization(build_l10n("deu",
                                      definition: [{ "content" => "def" }],
                                      entry_status: "valid"))

      mc2 = Glossarist::ManagedConcept.new(data: { id: "2" })
      mc2.add_localization(build_l10n("eng", entry_status: "draft"))

      [mc1, mc2]
    end

    def build_l10n(lang, definition: nil, entry_status: nil, sources: nil)
      data = { "language_code" => lang }
      data["definition"] = definition if definition
      data["entry_status"] = entry_status if entry_status
      data["sources"] = sources if sources
      Glossarist::LocalizedConcept.of_yaml({ "data" => data })
    end

    it "computes statistics from concepts" do
      metadata = described_class.from_concepts(concepts)

      expect(metadata.concept_count).to eq(2)
      expect(metadata.languages).to contain_exactly("eng", "deu")
      expect(metadata.statistics.concepts_by_status).to eq({ "valid" => 2,
                                                             "draft" => 1 })
      expect(metadata.statistics.concepts_with_definitions).to eq(2)
      expect(metadata.statistics.concepts_with_sources).to eq(1)
    end

    it "uses register data for title/description" do
      register = { "name" => "My Dataset", "description" => "A dataset" }
      metadata = described_class.from_concepts(concepts,
                                               register_data: register)

      expect(metadata.title).to eq("My Dataset")
      expect(metadata.description).to eq("A dataset")
    end

    it "overrides with options" do
      metadata = described_class.from_concepts(concepts,
                                               options: {
                                                 title: "Custom Title", owner: "Me"
                                               })

      expect(metadata.title).to eq("Custom Title")
      expect(metadata.owner).to eq("Me")
    end
  end

  describe "#to_yaml_hash" do
    it "serializes to hash" do
      metadata = described_class.new(
        title: "Test",
        concept_count: 5,
        languages: ["eng"],
        created_at: "2026-04-28",
        glossarist_version: "2.5.0",
        schema_version: "1",
        statistics: Glossarist::GcrStatistics.new(total_concepts: 5),
      )

      h = metadata.to_yaml_hash
      expect(h["title"]).to eq("Test")
      expect(h["concept_count"]).to eq(5)
      expect(h["schema_version"]).to eq("1")
    end

    it "excludes nil optional fields" do
      metadata = described_class.new(title: "Test")
      h = metadata.to_yaml_hash
      expect(h).not_to have_key("homepage")
      expect(h).not_to have_key("repository")
    end
  end
end
