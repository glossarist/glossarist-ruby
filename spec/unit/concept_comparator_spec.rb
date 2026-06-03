# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Glossarist::ConceptComparator do
  def build_managed_concept(termid, designation, definition)
    mc = Glossarist::ManagedConcept.new(data: { id: termid })
    l10n = Glossarist::LocalizedConcept.of_yaml({
                                                  "data" => {
                                                    "language_code" => "eng",
                                                    "terms" => [{
                                                      "type" => "expression", "designation" => designation
                                                    }],
                                                    "definition" => [{ "content" => definition }],
                                                  },
                                                })
    mc.add_localization(l10n)
    mc
  end

  describe "#compare" do
    it "reports identical datasets as fully matched" do
      concepts = [build_managed_concept("1", "test", "def")]
      result = described_class.new(new_concepts: concepts,
                                   old_concepts: concepts).compare

      expect(result.new_count).to eq(1)
      expect(result.old_count).to eq(1)
      expect(result.matched).to eq(["1"])
      expect(result.new_only).to be_empty
      expect(result.old_only).to be_empty
    end

    it "reports concepts only in new dataset" do
      new_concepts = [build_managed_concept("1", "test", "def")]
      result = described_class.new(
        new_concepts: new_concepts, old_concepts: [],
      ).compare(show_diffs: false)

      expect(result.new_only).to eq(["1"])
      expect(result.matched).to be_empty
    end

    it "reports concepts only in old dataset" do
      old_concepts = [build_managed_concept("1", "test", "def")]
      result = described_class.new(
        new_concepts: [], old_concepts: old_concepts,
      ).compare(show_diffs: false)

      expect(result.old_only).to eq(["1"])
      expect(result.matched).to be_empty
    end

    it "computes diffs for matched concepts" do
      new_concepts = [build_managed_concept("1", "new term", "new def")]
      old_concepts = [build_managed_concept("1", "old term", "old def")]

      result = described_class.new(
        new_concepts: new_concepts, old_concepts: old_concepts,
      ).compare

      expect(result.diffs.length).to eq(1)
      diff = result.diffs.first
      expect(diff).to be_a(Glossarist::ConceptDiff)
      expect(diff.concept_id).to eq("1")
      expect(diff.similarity).to be < 100
      expect(diff.diff_tree).to be_a(String)
    end

    it "skips diffs when show_diffs is false" do
      new_concepts = [build_managed_concept("1", "test", "def")]
      old_concepts = [build_managed_concept("1", "test", "def")]

      result = described_class.new(
        new_concepts: new_concepts, old_concepts: old_concepts,
      ).compare(show_diffs: false)

      expect(result.diffs).to be_empty
    end

    it "strips ANSI codes from diff tree" do
      new_concepts = [build_managed_concept("1", "new", "def")]
      old_concepts = [build_managed_concept("1", "old", "def")]

      result = described_class.new(
        new_concepts: new_concepts, old_concepts: old_concepts,
      ).compare

      expect(result.diffs.first.diff_tree).not_to include("\e[")
    end

    it "sorts diffs by similarity descending" do
      new_concepts = [
        build_managed_concept("1", "a", "same"),
        build_managed_concept("2", "x", "completely different def"),
      ]
      old_concepts = [
        build_managed_concept("1", "a", "same"),
        build_managed_concept("2", "y", "other"),
      ]

      result = described_class.new(
        new_concepts: new_concepts, old_concepts: old_concepts,
      ).compare

      ids = result.diffs.map(&:concept_id)
      expect(ids).to eq(ids.sort_by { |id|
        result.diffs.find { |d|
          d.concept_id == id
        }.similarity
      }.reverse)
    end

    it "returns ComparisonResult serializable to JSON" do
      concepts = [build_managed_concept("1", "test", "def")]
      result = described_class.new(
        new_concepts: concepts, old_concepts: concepts,
      ).compare(show_diffs: false)

      json = result.to_json
      parsed = JSON.parse(json)
      expect(parsed["new_count"]).to eq(1)
      expect(parsed["matched"]).to eq(["1"])
    end

    it "returns ComparisonResult serializable to YAML" do
      concepts = [build_managed_concept("1", "test", "def")]
      result = described_class.new(
        new_concepts: concepts, old_concepts: concepts,
      ).compare(show_diffs: false)

      yaml = result.to_yaml
      parsed = YAML.safe_load(yaml)
      expect(parsed["new_count"]).to eq(1)
    end

    it "returns empty result for two empty datasets" do
      result = described_class.new(
        new_concepts: [], old_concepts: [],
      ).compare

      expect(result.new_count).to eq(0)
      expect(result.old_count).to eq(0)
      expect(result.matched).to be_empty
      expect(result.new_only).to be_empty
      expect(result.old_only).to be_empty
    end
  end
end
