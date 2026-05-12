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
end
