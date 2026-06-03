# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::BibliographyData do
  let(:yaml) do
    <<~YAML
      ---
      ref_1:
        reference: ISO 704
        title: Terminology work
      ref_2:
        reference: ISO 10241-1
        title: Terminological entries
    YAML
  end

  describe "YAML round-trip" do
    it "parses YAML into entries" do
      bib = described_class.from_yaml(yaml)
      expect(bib.entries.length).to eq(2)
      expect(bib.entries.first.citation_key).to eq("ref_1")
      expect(bib.entries.first.data["reference"]).to eq("ISO 704")
    end

    it "round-trips through YAML" do
      bib = described_class.from_yaml(yaml)
      reloaded = described_class.from_yaml(bib.to_yaml)
      expect(reloaded.entries.length).to eq(2)
      expect(reloaded.find("ref_2").data["title"]).to eq("Terminological entries")
    end
  end

  describe "#find" do
    it "finds entry by citation key" do
      bib = described_class.from_yaml(yaml)
      entry = bib.find("ref_1")
      expect(entry).not_to be_nil
      expect(entry.data["reference"]).to eq("ISO 704")
    end

    it "returns nil for missing key" do
      bib = described_class.from_yaml(yaml)
      expect(bib.find("nonexistent")).to be_nil
    end
  end

  describe "#keys" do
    it "returns all citation keys" do
      bib = described_class.from_yaml(yaml)
      expect(bib.keys).to contain_exactly("ref_1", "ref_2")
    end
  end

  describe "#[]" do
    it "returns entry data by citation key" do
      bib = described_class.from_yaml(yaml)
      expect(bib["ref_1"]["reference"]).to eq("ISO 704")
    end
  end

  describe "empty bibliography" do
    it "initializes with empty entries" do
      bib = described_class.new
      expect(bib.entries).to be_empty
      expect(bib.keys).to be_empty
    end
  end

  describe "with real bibliography fixture" do
    it "loads isotc204 bibliography" do
      path = File.expand_path("../../isotc204-glossary/bibliography.yaml",
                              __dir__)
      skip "isotc204 fixture not found" unless File.exist?(path)
      bib = described_class.from_yaml(File.read(path, encoding: "utf-8"))
      expect(bib.entries.length).to be > 0
      expect(bib.keys).to include("ref_1")
    end
  end
end
