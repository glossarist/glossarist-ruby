# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::BibliographicReference do
  describe "#initialize" do
    it "stores anchor" do
      ref = described_class.new(anchor: "ISO_9000")
      expect(ref.anchor).to eq("ISO_9000")
    end
  end

  describe "#dedup_key" do
    it "returns the anchor" do
      ref = described_class.new(anchor: "ISO_9000")
      expect(ref.dedup_key).to eq("ISO_9000")
    end

    it "returns same key for same anchor" do
      ref1 = described_class.new(anchor: "ISO_9000")
      ref2 = described_class.new(anchor: "ISO_9000")
      expect(ref1.dedup_key).to eq(ref2.dedup_key)
    end
  end

  # A BibliographicReference is never an inline {{cite:...}} mention,
  # never a local concept cross-ref, never an external concept cross-ref.
  # These predicates let validation rules (e.g. CiteRefIntegrityRule) call
  # a uniform protocol on mixed collections of (BibliographicReference,
  # ConceptReference) without type-checking.
  describe "#cite?" do
    it "returns false" do
      expect(described_class.new(anchor: "x")).not_to be_cite
    end
  end

  describe "#local?" do
    it "returns false" do
      expect(described_class.new(anchor: "x")).not_to be_local
    end
  end

  describe "#external?" do
    it "returns false" do
      expect(described_class.new(anchor: "x")).not_to be_external
    end
  end
end
