# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::BibliographyData do
  let(:yaml) do
    <<~YAML
      ---
      bibliography:
      - id: ref_1
        reference: ISO 704
        title: Terminology work
      - id: ref_2
        reference: ISO 10241-1
        title: Terminological entries
    YAML
  end

  describe "YAML round-trip" do
    it "parses the entries from the wrapped mapping" do
      bib = described_class.from_yaml(yaml)
      expect(bib.entries.length).to eq(2)
      expect(bib.entries.first).to be_a(Glossarist::BibliographyEntry)
      expect(bib.entries.first.id).to eq("ref_1")
      expect(bib.entries.first.reference).to eq("ISO 704")
    end

    it "round-trips through the wrapped YAML" do
      bib = described_class.from_yaml(yaml)
      reloaded = described_class.from_yaml(bib.to_yaml)
      expect(reloaded.entries.length).to eq(2)
      expect(reloaded.find("ref_2").title).to eq("Terminological entries")
    end

    it "serializes as a single-key mapping (bibliography: [...]), not a stray array" do
      parsed = YAML.safe_load(described_class.from_yaml(yaml).to_yaml)
      expect(parsed.keys).to eq(["bibliography"])
      expect(parsed["bibliography"]).to be_an(Array)
      expect(parsed["bibliography"].first).to eq("id" => "ref_1",
                                                 "reference" => "ISO 704",
                                                 "title" => "Terminology work")
    end
  end

  describe "#find" do
    it "finds entry by id" do
      entry = described_class.from_yaml(yaml).find("ref_1")
      expect(entry).to be_a(Glossarist::BibliographyEntry)
      expect(entry.reference).to eq("ISO 704")
    end

    it "returns nil for a missing id" do
      expect(described_class.from_yaml(yaml).find("nonexistent")).to be_nil
    end
  end

  describe "#keys" do
    it "returns all entry ids" do
      expect(described_class.from_yaml(yaml).keys).to contain_exactly("ref_1", "ref_2")
    end
  end

  describe "#[]" do
    it "returns the typed entry by id" do
      expect(described_class.from_yaml(yaml)["ref_1"].reference).to eq("ISO 704")
    end
  end

  describe "empty bibliography" do
    it "initializes with empty entries" do
      bib = described_class.new
      expect(bib.entries).to be_empty
      expect(bib.keys).to be_empty
    end

    it "round-trips an empty bibliography" do
      reloaded = described_class.from_yaml(described_class.new.to_yaml)
      expect(reloaded.entries).to eq([])
    end
  end

  describe "loading a file" do
    let(:path) do
      File.expand_path("../fixtures/bibliography.yaml", __dir__)
    end

    it "loads a V3-syntax bibliography file via from_file" do
      skip "fixture not found" unless File.exist?(path)
      bib = described_class.from_file(path)
      expect(bib).to be_a(Glossarist::BibliographyData)
      expect(bib.entries).to be_an(Array)
      expect(bib.entries).not_to be_empty
      expect(bib.keys).to include("ref_1", "iso_std_iso_15704_en")
      expect(bib.find("ref_3").link).to match(%r{unece\.org})
    end

    it "returns nil when the file is absent" do
      expect(described_class.from_file("/nonexistent/bibliography.yaml")).to be_nil
    end
  end
end
