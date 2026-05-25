# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::ComparisonResult do
  it "serializes to JSON" do
    result = described_class.new(new_count: 10, old_count: 8)
    parsed = JSON.parse(result.to_json)
    expect(parsed["new_count"]).to eq(10)
    expect(parsed["old_count"]).to eq(8)
    expect(parsed["matched"]).to eq(nil)
  end

  it "initializes empty collections" do
    result = described_class.new
    expect(result.matched).to eq([])
    expect(result.new_only).to eq([])
    expect(result.old_only).to eq([])
    expect(result.diffs).to eq([])
  end

  describe "#summary" do
    it "reports positive diff" do
      result = described_class.new(new_count: 10, old_count: 8,
                                   matched: ["1"], new_only: ["2", "3"],
                                   old_only: [])
      expect(result.summary).to include("+2 new")
      expect(result.summary).to include("1 matched")
    end

    it "reports negative diff" do
      result = described_class.new(new_count: 5, old_count: 8,
                                   matched: ["1"], new_only: [],
                                   old_only: ["a", "b", "c"])
      expect(result.summary).to include("3 removed")
    end

    it "reports no change" do
      result = described_class.new(new_count: 5, old_count: 5)
      expect(result.summary).to include("no change")
    end
  end
end

RSpec.describe Glossarist::ConceptDiff do
  it "round-trips through YAML" do
    diff = described_class.new(concept_id: "1", similarity: 95.5,
                               diff_tree: "some tree")
    parsed = YAML.safe_load(diff.to_yaml)
    expect(parsed["concept_id"]).to eq("1")
    expect(parsed["similarity"]).to eq(95.5)
  end
end
