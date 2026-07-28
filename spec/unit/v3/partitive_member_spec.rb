# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::PartitiveMember do
  let(:ref) { Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2") }

  describe "construction" do
    it "accepts ref + presence + count + is_delimiting" do
      member = described_class.new(
        ref: ref,
        presence: "optional",
        count: "exactly_one",
        is_delimiting: true,
      )
      expect(member.ref.id).to eq("1.2")
      expect(member.presence).to eq("optional")
      expect(member.count).to eq("exactly_one")
      expect(member.is_delimiting).to be(true)
      expect(member).to be_delimiting
    end

    it "defaults presence to required and count to exactly_one when omitted" do
      member = described_class.new(ref: ref)
      expect(member.presence).to eq("required")
      expect(member.count).to eq("exactly_one")
      expect(member).to be_required
    end

    it "defaults is_delimiting to false when omitted" do
      member = described_class.new(ref: ref)
      expect(member.is_delimiting).to be(false)
    end
  end

  describe "#iso704_name (derived)" do
    it "maps required + exactly_one to compulsory" do
      member = described_class.new(ref: ref)
      expect(member.iso704_name).to eq("compulsory")
    end

    it "maps optional + exactly_one to optional" do
      member = described_class.new(ref: ref, presence: "optional")
      expect(member.iso704_name).to eq("optional")
    end

    it "maps required + multiple to compulsory_multiple" do
      member = described_class.new(ref: ref, count: "multiple")
      expect(member.iso704_name).to eq("compulsory_multiple")
    end

    it "maps optional + multiple to optional_multiple" do
      member = described_class.new(ref: ref, presence: "optional", count: "multiple")
      expect(member.iso704_name).to eq("optional_multiple")
    end

    it "maps required + at_least_one to compulsory_at_least_one" do
      member = described_class.new(ref: ref, count: "at_least_one")
      expect(member.iso704_name).to eq("compulsory_at_least_one")
    end
  end

  describe "#validate!" do
    it "raises on empty ref" do
      member = described_class.new(ref: Glossarist::V3::ConceptRef.new)
      expect { member.validate! }.to raise_error(ArgumentError, /non-empty ConceptRef/)
    end

    it "raises on invalid presence value" do
      member = described_class.new(ref: ref, presence: "maybe")
      expect { member.validate! }.to raise_error(ArgumentError, /invalid value/)
    end

    it "raises on invalid count value" do
      member = described_class.new(ref: ref, count: "many")
      expect { member.validate! }.to raise_error(ArgumentError, /invalid value/)
    end

    it "raises on optional + at_least_one (invalid combination)" do
      member = described_class.new(ref: ref, presence: "optional", count: "at_least_one")
      expect { member.validate! }
        .to raise_error(ArgumentError, /collapses to optional \+ multiple/)
    end

    it "accepts text-only ref (external concept form)" do
      member = described_class.new(
        ref: Glossarist::V3::ConceptRef.new(text: "quantum field theory"),
      )
      expect { member.validate! }.not_to raise_error
    end
  end

  describe "predicates" do
    it "required? is true for default" do
      expect(described_class.new(ref: ref)).to be_required
    end

    it "optional? is true for presence: optional" do
      member = described_class.new(ref: ref, presence: "optional")
      expect(member).to be_optional
      expect(member).not_to be_required
    end

    it "delimiting? is true when is_delimiting: true" do
      member = described_class.new(ref: ref, is_delimiting: true)
      expect(member).to be_delimiting
    end
  end

  describe "round-trip YAML" do
    it "round-trips a member with non-default presence and delimiting" do
      member = described_class.new(
        ref: ref,
        presence: "optional",
        count: "multiple",
        is_delimiting: true,
      )
      restored = described_class.from_yaml(member.to_yaml)
      expect(restored.ref.id).to eq("1.2")
      expect(restored.presence).to eq("optional")
      expect(restored.count).to eq("multiple")
      expect(restored.is_delimiting).to be(true)
      expect(restored.iso704_name).to eq("optional_multiple")
    end
  end

  describe "ISO 704:2022 mouse example" do
    it "models delimiting compulsory part (mouse ball)" do
      member = described_class.new(
        ref: Glossarist::V3::ConceptRef.new(source: "ISO 704", id: "mouse-ball"),
        is_delimiting: true,
      )
      expect(member).to be_required
      expect(member.iso704_name).to eq("compulsory")
      expect(member).to be_delimiting
    end

    it "models non-delimiting optional part (mouse wheel)" do
      member = described_class.new(
        ref: Glossarist::V3::ConceptRef.new(source: "ISO 704", id: "mouse-wheel"),
        presence: "optional",
        is_delimiting: false,
      )
      expect(member).to be_optional
      expect(member.iso704_name).to eq("optional")
      expect(member).not_to be_delimiting
    end
  end
end
