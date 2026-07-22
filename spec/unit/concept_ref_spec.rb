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
end
