# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Glossarist::RegisterData do
  describe "YAML round-trip" do
    let(:yaml) do
      <<~YAML
        ---
        name: Geolexica for Intelligent Transport Systems
        description: Vocabulary for ITS
        subregisters:
          eng:
      YAML
    end

    it "parses YAML into typed attributes" do
      rd = described_class.from_yaml(yaml)
      expect(rd.name).to eq("Geolexica for Intelligent Transport Systems")
      expect(rd.description).to eq("Vocabulary for ITS")
      expect(rd.subregisters).to eq({ "eng" => nil })
    end

    it "round-trips through YAML" do
      rd = described_class.from_yaml(yaml)
      reloaded = described_class.from_yaml(rd.to_yaml)
      expect(reloaded.name).to eq(rd.name)
      expect(reloaded.description).to eq(rd.description)
    end
  end

  describe "both id and shortname keys" do
    it "maps id: to shortname attribute" do
      rd = described_class.from_yaml("---\nid: tc204\n")
      expect(rd.shortname).to eq("tc204")
    end

    it "maps shortname: to shortname attribute" do
      rd = described_class.from_yaml("---\nshortname: tc204\n")
      expect(rd.shortname).to eq("tc204")
    end
  end

  describe "backward-compatible [] access" do
    let(:rd) do
      described_class.new(
        shortname: "tc204",
        name: "ITS Vocabulary",
        version: "1.0.0",
        schema_version: "3",
      )
    end

    it "returns shortname for 'shortname' key" do
      expect(rd["shortname"]).to eq("tc204")
    end

    it "returns shortname for 'id' key" do
      expect(rd["id"]).to eq("tc204")
    end

    it "returns name for 'name' key" do
      expect(rd["name"]).to eq("ITS Vocabulary")
    end

    it "returns nil for unknown key" do
      expect(rd["nonexistent"]).to be_nil
    end
  end

  describe "#to_h" do
    it "returns hash with non-nil attributes" do
      rd = described_class.new(shortname: "tc204", name: "Test")
      h = rd.to_h
      expect(h["shortname"]).to eq("tc204")
      expect(h["name"]).to eq("Test")
      expect(h).not_to have_key("version")
    end
  end

  describe "#dig" do
    it "returns attribute value for single key" do
      rd = described_class.new(shortname: "tc204", name: "Test")
      expect(rd["shortname"]).to eq("tc204")
    end

    it "returns nil for empty args" do
      rd = described_class.new(shortname: "tc204")
      expect(rd.dig).to be_nil
    end
  end

  describe ".from_file" do
    let(:tmpdir) { Dir.mktmpdir }
    after { FileUtils.rm_rf(tmpdir) }

    it "loads from a YAML file" do
      path = File.join(tmpdir, "register.yaml")
      File.write(path, "---\nname: Test\nshortname: test\n")
      rd = described_class.from_file(path)
      expect(rd.name).to eq("Test")
      expect(rd.shortname).to eq("test")
    end

    it "returns nil for missing file" do
      expect(described_class.from_file("/nonexistent")).to be_nil
    end
  end

  describe "with real register.yaml fixtures" do
    it "loads isotc204 register" do
      path = File.expand_path("../../isotc204-glossary/register.yaml", __dir__)
      skip "isotc204 fixture not found" unless File.exist?(path)
      rd = described_class.from_file(path)
      expect(rd.name).to include("Intelligent Transport Systems")
      expect(rd.subregisters).to include("eng")
    end

    it "loads isotc211 register" do
      path = File.expand_path("../../isotc211-glossary/register.yaml", __dir__)
      skip "isotc211 fixture not found" unless File.exist?(path)
      rd = described_class.from_file(path)
      expect(rd.name).to include("ISO/TC 211")
      expect(rd.subregisters.keys.length).to be >= 10
    end
  end
end
