# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::TypeSharedPlurality do
  describe "construction" do
    it "accepts is_shared, is_uncertain, shared_type" do
      plural = described_class.new(
        is_shared: true,
        is_uncertain: false,
        shared_type: Glossarist::V3::ConceptRef.new(source: "VIM", id: "type-1"),
      )
      expect(plural.is_shared).to be(true)
      expect(plural.is_uncertain).to be(false)
      expect(plural.shared_type.id).to eq("type-1")
    end

    it "defaults is_uncertain to false when omitted" do
      plural = described_class.new(is_shared: true)
      expect(plural.is_uncertain).to be(false)
    end
  end

  describe "#validate!" do
    it "raises when is_shared is missing" do
      plural = described_class.new
      expect { plural.validate! }
        .to raise_error(ArgumentError, /is_shared is required/)
    end

    it "raises when is_uncertain is true without is_shared" do
      plural = described_class.new(is_shared: false, is_uncertain: true)
      expect { plural.validate! }
        .to raise_error(ArgumentError, /is_uncertain requires is_shared: true/)
    end

    it "passes for is_shared: true with is_uncertain: true" do
      plural = described_class.new(is_shared: true, is_uncertain: true)
      expect { plural.validate! }.not_to raise_error
    end
  end

  describe "round-trip YAML" do
    it "round-trips a full plurality block" do
      plural = described_class.new(
        is_shared: true,
        is_uncertain: true,
        shared_type: Glossarist::V3::ConceptRef.new(source: "VIM", id: "type-1"),
      )
      restored = described_class.from_yaml(plural.to_yaml)
      expect(restored.is_shared).to be(true)
      expect(restored.is_uncertain).to be(true)
      expect(restored.shared_type.id).to eq("type-1")
    end
  end
end
