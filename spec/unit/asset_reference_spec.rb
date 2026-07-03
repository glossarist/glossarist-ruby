# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::AssetReference do
  subject(:ref) { described_class.new(path: path) }

  let(:path) { "images/logo.png" }

  it_behaves_like "a Glossarist::Reference"

  describe "#initialize" do
    it "stores path" do
      expect(ref.path).to eq("images/logo.png")
    end
  end

  describe "#dedup_key" do
    it "returns the path" do
      expect(ref.dedup_key).to eq("images/logo.png")
    end

    it "returns same key for same path" do
      ref1 = described_class.new(path: "images/a.png")
      ref2 = described_class.new(path: "images/a.png")
      expect(ref1.dedup_key).to eq(ref2.dedup_key)
    end
  end

  # AssetReference inherits the protocol defaults (all three predicates
  # false) from Glossarist::Reference — an image path is never a concept
  # cross-ref.
  describe "#cite?" do
    it { expect(ref).not_to be_cite }
  end

  describe "#local?" do
    it { expect(ref).not_to be_local }
  end

  describe "#external?" do
    it { expect(ref).not_to be_external }
  end
end
