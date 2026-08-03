# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Mentions::Parser do
  describe ".parse" do
    it "returns text segments between mentions" do
      segments = described_class.parse("Hello {{concept:VIM:1}} world")
      expect(segments.map { |s| s[:kind] }).to eq(%w[text concept text])
      expect(segments[0][:content]).to eq("Hello ")
      expect(segments[2][:content]).to eq(" world")
    end

    it "returns empty text for a string with no mentions" do
      segments = described_class.parse("plain text")
      expect(segments).to eq([{ kind: "text", content: "plain text" }])
    end

    it "returns empty for nil input" do
      expect(described_class.parse(nil)).to eq([{ kind: "text", content: "" }])
    end
  end

  describe "concept kind" do
    it "parses {{concept:DATASET:ID}}" do
      s = described_class.parse("{{concept:VIM:112-02-09}}").first
      expect(s[:kind]).to eq("concept")
      expect(s[:target]).to eq(type: "dataset_qualified", dataset: "VIM", id: "112-02-09")
      expect(s[:label]).to be_nil
    end

    it "parses {{concept:DATASET:ID, label}}" do
      s = described_class.parse("{{concept:VIM:112-02-09, measurement result}}").first
      expect(s[:label]).to eq("measurement result")
    end

    it "parses {{concept:urn:...}}" do
      s = described_class.parse("{{concept:urn:iec:std:iec:60050:702-02-07}}").first
      expect(s[:target][:type]).to eq("urn")
    end

    it "rejects bare ID without dataset" do
      expect { described_class.parse("{{concept:112-01-10}}") }
        .to raise_error(Glossarist::Mentions::InvalidMentionError, /DATASET:ID/)
    end

    it "rejects URL on concept kind" do
      expect { described_class.parse("{{concept:https://x.io}}") }
        .to raise_error(Glossarist::Mentions::InvalidMentionError, /DATASET:ID/)
    end
  end

  describe "cite kind" do
    it "parses {{cite:DATASET:ID, label}}" do
      s = described_class.parse("{{cite:IEV:702-02-07, IEV 702-02-07}}").first
      expect(s[:kind]).to eq("cite")
      expect(s[:target]).to eq(type: "dataset_qualified", dataset: "IEV", id: "702-02-07")
      expect(s[:label]).to eq("IEV 702-02-07")
    end

    it "parses {{cite:urn:...}}" do
      s = described_class.parse("{{cite:urn:iec:std:iec:60050:702-02-07}}").first
      expect(s[:target][:type]).to eq("urn")
    end

    it "rejects bare ID on cite kind" do
      expect { described_class.parse("{{cite:sourceId1}}") }
        .to raise_error(Glossarist::Mentions::InvalidMentionError, /DATASET:ID/)
    end
  end

  describe "fig/table/formula kinds" do
    it "parses {{fig:diagram_3}}" do
      s = described_class.parse("{{fig:diagram_3}}").first
      expect(s[:kind]).to eq("fig")
      expect(s[:target]).to eq(type: "entity_id", id: "diagram_3")
    end

    it "parses {{table:units, Units}}" do
      s = described_class.parse("{{table:units, Units}}").first
      expect(s[:label]).to eq("Units")
    end

    it "parses {{formula:ohm_law}}" do
      s = described_class.parse("{{formula:ohm_law}}").first
      expect(s[:kind]).to eq("formula")
    end

    it "accepts URN on fig kind" do
      s = described_class.parse("{{fig:urn:iec:std:iec:60050:figure:diagram_3}}").first
      expect(s[:target][:type]).to eq("urn")
    end

    it "rejects DATASET:ID on fig kind" do
      expect { described_class.parse("{{fig:VIM:diagram_3}}") }
        .to raise_error(Glossarist::Mentions::InvalidMentionError, /plain ID or URN/)
    end
  end

  describe "bib kind" do
    it "parses {{bib:ref_1}}" do
      s = described_class.parse("{{bib:ref_1}}").first
      expect(s[:kind]).to eq("bib")
      expect(s[:target]).to eq(type: "entity_id", id: "ref_1")
    end

    it "parses {{bib:ref_1, ISO 704:2022}}" do
      s = described_class.parse("{{bib:ref_1, ISO 704:2022}}").first
      expect(s[:label]).to eq("ISO 704:2022")
    end

    it "rejects URN on bib kind" do
      expect { described_class.parse("{{bib:urn:...}}") }
        .to raise_error(Glossarist::Mentions::InvalidMentionError, /plain ID/)
    end

    it "rejects DATASET:ID on bib kind" do
      expect { described_class.parse("{{bib:ISO:ref_1}}") }
        .to raise_error(Glossarist::Mentions::InvalidMentionError, /plain ID/)
    end
  end

  describe "link kind" do
    it "parses {{link:https://example.com}}" do
      s = described_class.parse("{{link:https://example.com}}").first
      expect(s[:kind]).to eq("link")
      expect(s[:target]).to eq(type: "url", url: "https://example.com")
    end

    it "parses {{link:URL, label}}" do
      s = described_class.parse("{{link:https://example.com, click here}}").first
      expect(s[:label]).to eq("click here")
    end

    it "rejects non-URL" do
      expect { described_class.parse("{{link:/internal/page}}") }
        .to raise_error(Glossarist::Mentions::InvalidMentionError, /https/)
    end
  end

  describe "image kind" do
    it "parses {{image:figures/wave.svg, Sine wave}}" do
      s = described_class.parse("{{image:figures/wave.svg, Sine wave}}").first
      expect(s[:kind]).to eq("image")
      expect(s[:target]).to eq(type: "path", path: "figures/wave.svg")
      expect(s[:label]).to eq("Sine wave")
    end

    it "parses {{image:https://example.com/img.png}}" do
      s = described_class.parse("{{image:https://example.com/img.png}}").first
      expect(s[:target][:type]).to eq("url")
    end
  end

  describe "rejection — no bare text" do
    it "rejects bare text without kind prefix" do
      expect { described_class.parse("{{measurement unit}}") }
        .to raise_error(Glossarist::Mentions::InvalidMentionError, /Missing kind prefix/)
    end

    it "rejects bare numeric without kind prefix" do
      expect { described_class.parse("{{112-01-10}}") }
        .to raise_error(Glossarist::Mentions::InvalidMentionError, /Missing kind prefix/)
    end

    it "rejects unknown kind" do
      expect { described_class.parse("{{ref:IEV:702-02-07}}") }
        .to raise_error(Glossarist::Mentions::InvalidMentionError, /Unknown kind/)
    end
  end

  describe "DATASET:ID colon splitting" do
    it "splits on LAST colon (handles internal colons)" do
      s = described_class.parse("{{concept:ISO:10241-1:2011}}").first
      expect(s[:target][:dataset]).to eq("ISO:10241-1")
      expect(s[:target][:id]).to eq("2011")
    end
  end

  describe "positions" do
    it "includes start/end offsets and raw text" do
      text = "See {{concept:VIM:1}} here."
      s = described_class.parse(text)[1]
      expect(s[:raw]).to eq("{{concept:VIM:1}}")
      expect(s[:start]).to eq(4)
      expect(s[:end]).to eq(21)
    end
  end
end
