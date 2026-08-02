# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Glossarist.parse_mention (PROMPT-NOW P1)" do
  # The parsed shapes MUST match the JS library's output exactly.
  # Same keys, same values, same symbol-as-string for `kind`.

  describe "link kind" do
    it "parses {{link:URL}}" do
      expect(Glossarist.parse_mention("{{link:https://example.com/page}}"))
        .to eq(kind: "link-ref", uri: "https://example.com/page", label: nil)
    end

    it "parses {{link:URL, label}}" do
      expect(Glossarist.parse_mention("{{link:https://example.com, click here}}"))
        .to eq(kind: "link-ref", uri: "https://example.com", label: "click here")
    end

    it "is case-insensitive on the prefix" do
      expect(Glossarist.parse_mention("{{LINK:https://x.io}}"))
        .to eq(kind: "link-ref", uri: "https://x.io", label: nil)
    end
  end

  describe "image kind" do
    it "parses {{image:src}}" do
      expect(Glossarist.parse_mention("{{image:diagram.png}}"))
        .to eq(kind: "image-ref", src: "diagram.png", alt: nil)
    end

    it "parses {{image:src, alt}}" do
      expect(Glossarist.parse_mention("{{image:diagram.png, The diagram}}"))
        .to eq(kind: "image-ref", src: "diagram.png", alt: "The diagram")
    end

    it "uses `alt` not `label` (embed, not link)" do
      result = Glossarist.parse_mention("{{image:x.png, caption}}")
      expect(result.key?(:label)).to be(false)
      expect(result.key?(:alt)).to be(true)
    end
  end

  describe "bib kind" do
    it "parses {{bib:id}}" do
      expect(Glossarist.parse_mention("{{bib:ref_1}}"))
        .to eq(kind: "bib-ref", id: "ref_1", label: nil)
    end

    it "parses {{bib:id, label}}" do
      expect(Glossarist.parse_mention("{{bib:ref_1, ISO 704}}"))
        .to eq(kind: "bib-ref", id: "ref_1", label: "ISO 704")
    end
  end

  describe "existing kinds (unified shape)" do
    it "parses cite: as cite-ref" do
      expect(Glossarist.parse_mention("{{cite:103-01-02}}"))
        .to eq(kind: "cite-ref", id: "103-01-02", label: nil)
    end

    it "parses fig: and figure: as fig-ref" do
      expect(Glossarist.parse_mention("{{fig:diagram-1}}"))
        .to eq(kind: "fig-ref", id: "diagram-1", label: nil)
      expect(Glossarist.parse_mention("{{figure:diagram-1, Caption}}"))
        .to eq(kind: "fig-ref", id: "diagram-1", label: "Caption")
    end

    it "parses table: and tbl: as table-ref" do
      expect(Glossarist.parse_mention("{{table:tbl-1}}"))
        .to eq(kind: "table-ref", id: "tbl-1", label: nil)
      expect(Glossarist.parse_mention("{{tbl:tbl-1}}"))
        .to eq(kind: "table-ref", id: "tbl-1", label: nil)
    end

    it "parses formula: and eq: as formula-ref" do
      expect(Glossarist.parse_mention("{{formula:eq-1}}"))
        .to eq(kind: "formula-ref", id: "eq-1", label: nil)
      expect(Glossarist.parse_mention("{{eq:eq-1}}"))
        .to eq(kind: "formula-ref", id: "eq-1", label: nil)
    end

    it "parses numeric id as local-concept-ref" do
      expect(Glossarist.parse_mention("{{103-01-02}}"))
        .to eq(kind: "local-concept-ref", id: "103-01-02", label: nil)
    end

    it "parses bare text as designation-ref" do
      expect(Glossarist.parse_mention("{{measure}}"))
        .to eq(kind: "designation-ref", designation: "measure")
    end

    it "parses urn: as urn-ref" do
      urn = "urn:iec:std:iec:60050::#con-103-01-02"
      expect(Glossarist.parse_mention("{{#{urn}}}"))
        .to eq(kind: "urn-ref", urn: urn, label: nil)
    end
  end

  describe "input handling" do
    it "returns nil for non-String input" do
      expect(Glossarist.parse_mention(nil)).to be_nil
      expect(Glossarist.parse_mention(123)).to be_nil
    end

    it "returns nil when input is not a {{...}} mention" do
      expect(Glossarist.parse_mention("not a mention")).to be_nil
      expect(Glossarist.parse_mention("[link]")).to be_nil
    end

    it "strips whitespace around the braces" do
      expect(Glossarist.parse_mention("  {{link:https://x.io}}  "))
        .to eq(kind: "link-ref", uri: "https://x.io", label: nil)
    end

    it "treats empty label as nil (not empty string)" do
      expect(Glossarist.parse_mention("{{link:https://x.io, }}"))
        .to eq(kind: "link-ref", uri: "https://x.io", label: nil)
    end
  end

  describe "MentionKinds constants" do
    it "exposes kind strings" do
      expect(Glossarist::MentionKinds::LINK_REF).to eq("link-ref")
      expect(Glossarist::MentionKinds::IMAGE_REF).to eq("image-ref")
      expect(Glossarist::MentionKinds::BIB_REF).to eq("bib-ref")
      expect(Glossarist::MentionKinds::CITE_REF).to eq("cite-ref")
    end
  end
end
