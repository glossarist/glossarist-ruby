# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::GcrStatistics do
  def make_localization(lang: "eng", status: "valid", definition: nil,
                        sources: nil)
    data = {
      "language_code" => lang,
      "terms" => [{ "type" => "expression", "designation" => "t",
                    "normative_status" => "preferred" }],
      "definition" => definition || [{ "content" => "a definition" }],
      "entry_status" => status,
    }
    data["sources"] = sources if sources
    Glossarist::LocalizedConcept.of_yaml({ "data" => data })
  end

  def make_concept(id:, l10ns:)
    mc = Glossarist::ManagedConcept.new(data: { "id" => id })
    Array(l10ns).each { |l| mc.add_localization(l) }
    mc
  end

  describe ".from_concepts" do
    it "returns zero counts for an empty input" do
      stats = described_class.from_concepts([])
      expect(stats.total_concepts).to eq(0)
      expect(stats.languages).to eq([])
      expect(stats.concepts_by_status).to eq({})
      expect(stats.concepts_with_definitions).to eq(0)
      expect(stats.concepts_with_sources).to eq(0)
    end

    it "counts concepts and unique languages across all localizations" do
      concepts = [
        make_concept(id: "1", l10ns: [
                       make_localization(lang: "eng", status: "valid"),
                       make_localization(lang: "fra", status: "valid"),
                     ]),
        make_concept(id: "2", l10ns: [
                       make_localization(lang: "eng", status: "draft"),
                     ]),
      ]
      stats = described_class.from_concepts(concepts)
      expect(stats.total_concepts).to eq(2)
      expect(stats.languages.sort).to eq(%w[eng fra])
    end

    it "tallies entry_status counts into concepts_by_status" do
      concepts = [
        make_concept(id: "1", l10ns: [make_localization(status: "valid")]),
        make_concept(id: "2", l10ns: [make_localization(status: "valid")]),
        make_concept(id: "3", l10ns: [make_localization(status: "draft")]),
      ]
      stats = described_class.from_concepts(concepts)
      expect(stats.concepts_by_status["valid"]).to eq(2)
      expect(stats.concepts_by_status["draft"]).to eq(1)
    end

    it "counts concepts_with_definitions only for non-empty definitions" do
      with_def = make_localization(definition: [{ "content" => "x" }])
      empty_def = make_localization(definition: [])
      concepts = [
        make_concept(id: "1", l10ns: [with_def]),
        make_concept(id: "2", l10ns: [empty_def]),
      ]
      stats = described_class.from_concepts(concepts)
      expect(stats.concepts_with_definitions).to eq(1)
    end

    it "counts concepts_with_sources only for non-empty sources" do
      with_src = make_localization(sources: [{ "type" => "authoritative" }])
      no_src = make_localization
      concepts = [
        make_concept(id: "1", l10ns: [with_src]),
        make_concept(id: "2", l10ns: [no_src]),
      ]
      stats = described_class.from_concepts(concepts)
      expect(stats.concepts_with_sources).to eq(1)
    end
  end

  describe "YAML round-trip" do
    it "preserves all fields through to_yaml/from_yaml" do
      stats = described_class.new(
        total_concepts: 5,
        languages: %w[eng fra],
        concepts_by_status: { "valid" => 4, "draft" => 1 },
        concepts_with_definitions: 5,
        concepts_with_sources: 3,
      )
      reloaded = described_class.from_yaml(stats.to_yaml)
      expect(reloaded.total_concepts).to eq(5)
      expect(reloaded.languages.sort).to eq(%w[eng fra])
      expect(reloaded.concepts_with_definitions).to eq(5)
    end
  end

  describe ".count_with" do
    it "returns 0 for an unknown attribute" do
      expect(described_class.count_with([], :unknown)).to eq(0)
    end
  end
end
