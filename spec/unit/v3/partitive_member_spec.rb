# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::PartitiveMember do
  let(:ref) { Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2") }

  describe "construction" do
    it "accepts ref + certainty" do
      member = described_class.new(ref: ref, certainty: "confirmed")
      expect(member.ref.id).to eq("1.2")
      expect(member.certainty).to eq("confirmed")
      expect(member).to be_confirmed
    end

    it "defaults certainty to confirmed when omitted" do
      member = described_class.new(ref: ref)
      expect(member.certainty).to eq("confirmed")
    end
  end

  describe "#validate!" do
    it "raises on empty ref" do
      member = described_class.new(ref: Glossarist::V3::ConceptRef.new)
      expect { member.validate! }.to raise_error(ArgumentError, /non-empty ConceptRef/)
    end

    it "raises on invalid certainty value" do
      member = described_class.new(ref: ref, certainty: "maybe")
      expect { member.validate! }.to raise_error(ArgumentError, /invalid value/)
    end

    it "accepts text-only ref (external concept form)" do
      member = described_class.new(ref: Glossarist::V3::ConceptRef.new(text: "quantum field theory"))
      expect { member.validate! }.not_to raise_error
    end
  end

  describe "predicates" do
    it "confirmed? is true for default" do
      expect(described_class.new(ref: ref)).to be_confirmed
    end

    it "possible? is true for certainty: possible" do
      member = described_class.new(ref: ref, certainty: "possible")
      expect(member).to be_possible
      expect(member).not_to be_confirmed
    end
  end

  describe "round-trip YAML" do
    it "round-trips a member with certainty" do
      member = described_class.new(ref: ref, certainty: "possible")
      restored = described_class.from_yaml(member.to_yaml)
      expect(restored.ref.id).to eq("1.2")
      expect(restored.certainty).to eq("possible")
    end
  end
end
