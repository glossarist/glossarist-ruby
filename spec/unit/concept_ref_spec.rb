# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::ConceptRef do
  describe "standard concept reference" do
    it "holds source and id" do
      ref = described_class.new(source: "IEC", id: "60050-102-03")
      expect(ref.source).to eq("IEC")
      expect(ref.id).to eq("60050-102-03")
    end

    it "round-trips through YAML" do
      ref = described_class.new(source: "IEC", id: "60050-102-03")
      yaml = ref.to_yaml
      restored = described_class.from_yaml(yaml)

      expect(restored.source).to eq("IEC")
      expect(restored.id).to eq("60050-102-03")
    end
  end

  describe "text attribute (for lexical relationship targets)" do
    it "holds designation text" do
      ref = described_class.new(text: "measure")
      expect(ref.text).to eq("measure")
    end

    it "round-trips through YAML" do
      ref = described_class.new(text: "measure")
      yaml = ref.to_yaml
      restored = described_class.from_yaml(yaml)

      expect(restored.text).to eq("measure")
    end

    it "combines concept reference and designation text" do
      ref = described_class.new(source: "IEC", id: "102-08-01", text: "port")
      yaml = ref.to_yaml
      restored = described_class.from_yaml(yaml)

      expect(restored.source).to eq("IEC")
      expect(restored.id).to eq("102-08-01")
      expect(restored.text).to eq("port")
    end
  end

  describe "integration with RelatedConcept" do
    it "false_friend ref with text round-trips through YAML" do
      rc = Glossarist::RelatedConcept.new(
        type: "false_friend",
        content: { "eng" => "measure (English, musical sense)" },
      )
      rc.ref = described_class.new(text: "measure")

      yaml = rc.to_yaml
      restored = Glossarist::RelatedConcept.from_yaml(yaml)

      expect(restored.type).to eq("false_friend")
      expect(restored.ref.text).to eq("measure")
    end
  end

  describe ".qualified_id" do
    it "returns the id-only form for local refs" do
      expect(described_class.qualified_id(described_class.new(id: "1.2")))
        .to eq("1.2")
    end

    it "returns SOURCE:ID for external refs" do
      expect(described_class.qualified_id(described_class.new(source: "VIM", id: "1.2")))
        .to eq("VIM:1.2")
    end

    it "returns the text form when no id" do
      expect(described_class.qualified_id(described_class.new(text: "quantum field theory")))
        .to eq("quantum field theory")
    end

    it "prefixes source when only text is present" do
      expect(described_class.qualified_id(described_class.new(source: "X", text: "y")))
        .to eq("X:y")
    end

    it "returns nil for an empty ConceptRef" do
      expect(described_class.qualified_id(described_class.new)).to be_nil
    end

    it "returns nil for non-ConceptRef input" do
      expect(described_class.qualified_id(nil)).to be_nil
      expect(described_class.qualified_id("not a ref")).to be_nil
    end

    it "treats empty strings as missing" do
      r = described_class.new(source: "", id: "")
      expect(described_class.qualified_id(r)).to be_nil
    end
  end

  describe "#qualified_id (instance)" do
    it "delegates to the class method" do
      expect(described_class.new(source: "VIM", id: "1.2").qualified_id)
        .to eq("VIM:1.2")
    end
  end

  describe "#same_concept?" do
    it "is true for two refs with same source+id" do
      a = described_class.new(source: "VIM", id: "1.2")
      b = described_class.new(source: "VIM", id: "1.2")
      expect(a.same_concept?(b)).to be(true)
    end

    it "is true when only id matches (both local)" do
      a = described_class.new(id: "1.2")
      b = described_class.new(id: "1.2")
      expect(a.same_concept?(b)).to be(true)
    end

    it "is false when sources differ" do
      a = described_class.new(source: "VIM", id: "1.2")
      b = described_class.new(source: "ISO", id: "1.2")
      expect(a.same_concept?(b)).to be(false)
    end

    it "is false when one is local and the other has a source" do
      a = described_class.new(id: "1.2")
      b = described_class.new(source: "VIM", id: "1.2")
      expect(a.same_concept?(b)).to be(false)
    end
  end
end
