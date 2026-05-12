# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::AssetReference do
  describe "#initialize" do
    it "stores path" do
      ref = described_class.new(path: "images/logo.png")
      expect(ref.path).to eq("images/logo.png")
    end
  end

  describe "#dedup_key" do
    it "returns the path" do
      ref = described_class.new(path: "images/logo.png")
      expect(ref.dedup_key).to eq("images/logo.png")
    end

    it "returns same key for same path" do
      ref1 = described_class.new(path: "images/a.png")
      ref2 = described_class.new(path: "images/a.png")
      expect(ref1.dedup_key).to eq(ref2.dedup_key)
    end
  end
end
