# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Glossarist::Validation::BibliographyIndex do
  subject(:index) { described_class.new }

  describe "#register and #resolve?" do
    it "registers and resolves an anchor" do
      index.register("ISO 9000")
      expect(index.resolve?("ISO 9000")).to be true
    end

    it "normalizes spaces and slashes" do
      index.register("ISO/IEC 19111")
      expect(index.resolve?("ISO/IEC 19111")).to be true
    end

    it "returns false for unregistered anchors" do
      expect(index.resolve?("nonexistent")).to be false
    end
  end

  describe "#anchors" do
    it "returns all registered normalized anchors" do
      index.register("ISO 9000")
      index.register("IEC 60050")
      expect(index.anchors).to contain_exactly("ISO_9000", "IEC_60050")
    end
  end

  describe "#each_entry" do
    it "yields each entry hash with anchor and source" do
      index.register("ISO 9000", "source_obj")
      entries = []
      index.each_entry { |e| entries << e }
      expect(entries.size).to eq(1)
      expect(entries.first[:anchor]).to eq("ISO 9000")
      expect(entries.first[:source]).to eq("source_obj")
    end
  end

  describe ".build_from_concepts" do
    let(:concept) do
      mc = Glossarist::ManagedConcept.new(data: { id: "1" })
      l10n = Glossarist::LocalizedConcept.of_yaml({
                                                    "data" => {
                                                      "language_code" => "eng",
                                                      "terms" => [{
                                                        "type" => "expression", "designation" => "test"
                                                      }],
                                                      "sources" => [{
                                                        "type" => "authoritative",
                                                        "origin" => { "text" => "ISO 9000" },
                                                      }],
                                                    },
                                                  })
      mc.add_localization(l10n)
      mc
    end

    it "indexes sources from concept localizations" do
      index = described_class.build_from_concepts([concept])
      expect(index.resolve?("ISO 9000")).to be true
    end

    it "indexes sources from definition entries" do
      mc = Glossarist::ManagedConcept.new(data: { id: "2" })
      l10n = Glossarist::LocalizedConcept.of_yaml({
                                                    "data" => {
                                                      "language_code" => "eng",
                                                      "terms" => [{
                                                        "type" => "expression", "designation" => "test"
                                                      }],
                                                      "definition" => [{
                                                        "content" => "a definition",
                                                        "sources" => [{ "type" => "authoritative",
                                                                        "origin" => { "text" => "ISO 19115" } }],
                                                      }],
                                                    },
                                                  })
      mc.add_localization(l10n)
      index = described_class.build_from_concepts([mc])
      expect(index.resolve?("ISO 19115")).to be true
    end

    it "indexes bibliography.yaml when provided" do
      yaml = "ISO_9000:\n  id: ISO_9000\n  type: standard"
      index = described_class.build_from_concepts(
        [], bibliography_yaml: yaml
      )
      expect(index.resolve?("ISO_9000")).to be true
    end

    it "indexes bibliography.yaml from dataset path" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "bibliography.yaml"),
                   "IEC_60050:\n  id: IEC_60050\n  type: standard")
        index = described_class.build_from_concepts([], dataset_path: dir)
        expect(index.resolve?("IEC_60050")).to be true
      end
    end

    it "handles malformed bibliography YAML gracefully" do
      yaml = "invalid: [yaml: unclosed"
      index = described_class.build_from_concepts(
        [], bibliography_yaml: yaml
      )
      expect(index.anchors).to be_empty
    end

    it "handles bibliography.yaml with array format" do
      yaml = "- id: ISO_9000\n  type: standard\n- id: IEC_60050\n  type: standard"
      index = described_class.build_from_concepts(
        [], bibliography_yaml: yaml
      )
      expect(index.resolve?("ISO_9000")).to be true
      expect(index.resolve?("IEC_60050")).to be true
    end
  end
end
