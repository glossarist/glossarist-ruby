# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::PartitiveMember do
  let(:ref) { Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2") }

  describe "construction" do
    it "accepts ref + multiplicity + is_delimiting" do
      member = described_class.new(
        ref: ref,
        multiplicity: "optional",
        is_delimiting: true,
      )
      expect(member.ref.id).to eq("1.2")
      expect(member.multiplicity).to eq("optional")
      expect(member.is_delimiting).to be(true)
      expect(member).to be_delimiting
    end

    it "defaults multiplicity to compulsory when omitted" do
      member = described_class.new(ref: ref)
      expect(member.multiplicity).to eq("compulsory")
      expect(member).to be_compulsory
    end

    it "defaults is_delimiting to false when omitted" do
      member = described_class.new(ref: ref)
      expect(member.is_delimiting).to be(false)
    end

    it "accepts all 5 multiplicity values" do
      %w[compulsory optional compulsory_multiple optional_multiple at_least_one].each do |m|
        member = described_class.new(ref: ref, multiplicity: m)
        expect(member.multiplicity).to eq(m)
      end
    end
  end

  describe "#validate!" do
    it "raises on empty ref" do
      member = described_class.new(ref: Glossarist::V3::ConceptRef.new)
      expect { member.validate! }.to raise_error(ArgumentError, /non-empty ConceptRef/)
    end

    it "raises on invalid multiplicity value" do
      member = described_class.new(ref: ref, multiplicity: "maybe")
      expect { member.validate! }.to raise_error(ArgumentError, /invalid value/)
    end

    it "accepts text-only ref (external concept form)" do
      member = described_class.new(
        ref: Glossarist::V3::ConceptRef.new(text: "quantum field theory"),
      )
      expect { member.validate! }.not_to raise_error
    end
  end

  describe "predicates" do
    it "compulsory? is true for default" do
      expect(described_class.new(ref: ref)).to be_compulsory
    end

    it "optional? is true for multiplicity: optional" do
      member = described_class.new(ref: ref, multiplicity: "optional")
      expect(member).to be_optional
      expect(member).not_to be_compulsory
    end

    it "delimiting? is true when is_delimiting: true" do
      member = described_class.new(ref: ref, is_delimiting: true)
      expect(member).to be_delimiting
    end
  end

  describe "round-trip YAML" do
    it "round-trips a member with non-default multiplicity and delimiting" do
      member = described_class.new(
        ref: ref,
        multiplicity: "compulsory_multiple",
        is_delimiting: true,
      )
      restored = described_class.from_yaml(member.to_yaml)
      expect(restored.ref.id).to eq("1.2")
      expect(restored.multiplicity).to eq("compulsory_multiple")
      expect(restored.is_delimiting).to be(true)
    end
  end

  describe "ISO 704:2022 mouse example" do
    # Per ISO 704 §5.5.4.2.2: optomechanical mouse parts.
    # Delimiting (distinguish from mechanical/optical mice):
    #   mouse ball, x-axis roller, y-axis roller,
    #   infrared emitter, infrared sensor
    # Not delimiting: mouse button (all computer mice have buttons)
    # Optional: mouse wheel (not on all optomechanical mice)
    it "models delimiting compulsory parts" do
      member = described_class.new(
        ref: Glossarist::V3::ConceptRef.new(source: "ISO 704", id: "mouse-ball"),
        multiplicity: "compulsory",
        is_delimiting: true,
      )
      expect(member).to be_compulsory
      expect(member).to be_delimiting
    end

    it "models non-delimiting optional part (mouse wheel)" do
      member = described_class.new(
        ref: Glossarist::V3::ConceptRef.new(source: "ISO 704", id: "mouse-wheel"),
        multiplicity: "optional",
        is_delimiting: false,
      )
      expect(member).to be_optional
      expect(member).not_to be_delimiting
    end
  end
end
