# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Glossarist::RegisterData do
  describe "YAML round-trip" do
    let(:yaml) do
      <<~YAML
        ---
        shortname: tc204
        subregisters:
          eng:
      YAML
    end

    it "parses YAML into typed attributes" do
      rd = described_class.from_yaml(yaml)
      expect(rd.shortname).to eq("tc204")
      expect(rd.subregisters).to eq({ "eng" => nil })
    end

    it "round-trips through YAML" do
      rd = described_class.from_yaml(yaml)
      reloaded = described_class.from_yaml(rd.to_yaml)
      expect(reloaded.shortname).to eq(rd.shortname)
    end
  end

  describe "identity and lifecycle fields" do
    let(:yaml) do
      <<~YAML
        ---
        id: isotc204-ed3
        ref: ISO 14812 (Edition 3, draft)
        year: 2026
        urn: urn:iso:std:iso:14812:ed3
        status: current
        supersedes: isotc204-2025
        source_repo: https://github.com/ISO-TC204/iso14812
        ref_aliases:
          - ISO 14812 Ed3
        urn_aliases:
          - urn:iso:std:iso:14812:ed3*
      YAML
    end

    it "preserves all fields through round-trip" do
      rd = described_class.from_yaml(yaml)
      expect(rd.ref).to eq("ISO 14812 (Edition 3, draft)")
      expect(rd.year).to eq(2026)
      expect(rd.urn).to eq("urn:iso:std:iso:14812:ed3")
      expect(rd.status).to eq("current")
      expect(rd.supersedes).to eq("isotc204-2025")
      expect(rd.source_repo).to eq("https://github.com/ISO-TC204/iso14812")
      expect(rd.ref_aliases).to eq(["ISO 14812 Ed3"])
      expect(rd.urn_aliases).to eq(["urn:iso:std:iso:14812:ed3*"])
    end

    it "does not coerce localized name/description hashes to strings" do
      # Source register.yaml may carry name: as a localized hash. The gem
      # must NOT serialize this — it would produce lossy .to_s coercion.
      # Display metadata belongs in the deployment's site-config.yml.
      yaml_with_localized_name = <<~YAML
        ---
        id: test
        name:
          eng: Test Vocabulary
        description:
          eng: A test.
        year: 2024
      YAML
      rd = described_class.from_yaml(yaml_with_localized_name)
      reloaded = described_class.from_yaml(rd.to_yaml)
      expect(reloaded.year).to eq(2024)
      expect(reloaded.to_yaml).not_to include('{"eng"=>')
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

  describe ".from_file" do
    let(:tmpdir) { Dir.mktmpdir }
    after { FileUtils.rm_rf(tmpdir) }

    it "loads from a YAML file" do
      path = File.join(tmpdir, "register.yaml")
      File.write(path, "---\nshortname: test\nyear: 2024\n")
      rd = described_class.from_file(path)
      expect(rd.shortname).to eq("test")
      expect(rd.year).to eq(2024)
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
      expect(rd.shortname).to eq("isotc204")
      expect(rd.subregisters).to include("eng")
    end

    it "loads isotc211 register" do
      path = File.expand_path("../../isotc211-glossary/register.yaml", __dir__)
      skip "isotc211 fixture not found" unless File.exist?(path)
      rd = described_class.from_file(path)
      expect(rd.shortname).to eq("isotc211")
      expect(rd.subregisters.keys.length).to be >= 10
    end
  end
end
