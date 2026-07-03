# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::BibliographicReference do
  subject(:ref) { described_class.new(anchor: anchor) }

  let(:anchor) { "ISO_9000" }

  it_behaves_like "a Glossarist::Reference"

  describe "#initialize" do
    it "stores anchor" do
      expect(ref.anchor).to eq("ISO_9000")
    end
  end

  describe "#dedup_key" do
    it "returns the anchor" do
      expect(ref.dedup_key).to eq("ISO_9000")
    end

    it "returns same key for same anchor" do
      ref1 = described_class.new(anchor: "ISO_9000")
      ref2 = described_class.new(anchor: "ISO_9000")
      expect(ref1.dedup_key).to eq(ref2.dedup_key)
    end
  end

  # BibliographicReference inherits the protocol defaults (all three
  # predicates false) from Glossarist::Reference. A bibliographic xref is
  # never an inline {{cite:...}} mention, never a concept cross-ref.
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
