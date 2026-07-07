# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Pronunciation do
  describe "#initialize" do
    it "stores all attributes" do
      pron = described_class.new(
        content: "toːkjoː",
        language: "jpn",
        script: "Latn",
        country: "JP",
        system: "IPA",
      )
      expect(pron.content).to eq("toːkjoː")
      expect(pron.language).to eq("jpn")
      expect(pron.script).to eq("Latn")
      expect(pron.country).to eq("JP")
      expect(pron.system).to eq("IPA")
    end

    it "allows nil for optional attributes" do
      pron = described_class.new(content: "alpha")
      expect(pron.content).to eq("alpha")
      expect(pron.language).to be_nil
      expect(pron.script).to be_nil
    end
  end

  describe "YAML round-trip through Designation::Base" do
    let(:yaml) do
      <<~YAML
        ---
        type: expression
        designation: alpha
        normative_status: preferred
        pronunciation:
        - content: "ˈæl.fə"
          language: eng
          script: Latn
          system: IPA
      YAML
    end

    it "parses pronunciations from a designation's YAML" do
      desig = Glossarist::Designation::Base.of_yaml(YAML.safe_load(yaml))
      expect(desig.pronunciation.length).to eq(1)
      pron = desig.pronunciation.first
      expect(pron).to be_a(described_class)
      expect(pron.content).to eq("ˈæl.fə")
      expect(pron.system).to eq("IPA")
    end

    it "round-trips through YAML preserving all fields" do
      desig = Glossarist::Designation::Base.of_yaml(YAML.safe_load(yaml))
      reloaded = Glossarist::Designation::Base.of_yaml(
        YAML.safe_load(desig.to_yaml),
      )
      expect(reloaded.pronunciation.first.content).to eq("ˈæl.fə")
      expect(reloaded.pronunciation.first.system).to eq("IPA")
    end
  end

  describe "equality via ComparableModel" do
    it "two instances with identical attributes are ==" do
      a = described_class.new(content: "x", system: "IPA")
      b = described_class.new(content: "x", system: "IPA")
      expect(a).to eq(b)
    end

    it "differing system breaks equality" do
      a = described_class.new(content: "x", system: "IPA")
      b = described_class.new(content: "x", system: "Hepburn")
      expect(a).not_to eq(b)
    end
  end
end
