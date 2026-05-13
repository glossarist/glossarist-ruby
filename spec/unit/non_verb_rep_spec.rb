# frozen_string_literal: true

RSpec.describe Glossarist::NonVerbRep do
  let(:source) do
    Glossarist::ConceptSource.from_yaml({
      "type" => "authoritative",
      "status" => "identical",
    }.to_yaml)
  end

  describe "attributes" do
    it "accepts type as image, table, or formula" do
      %w[image table formula].each do |t|
        nvr = described_class.new(type: t, ref: "assets/diagram.svg")
        expect(nvr.type).to eq(t)
        expect(nvr.ref).to eq("assets/diagram.svg")
      end
    end

    it "accepts ref as URI reference" do
      nvr = described_class.new(
        type: "image",
        ref: "assets/images/figure-1.svg",
        text: "Diagram of the concept",
      )
      expect(nvr.ref).to eq("assets/images/figure-1.svg")
      expect(nvr.text).to eq("Diagram of the concept")
    end

    it "accepts sources collection" do
      nvr = described_class.new(
        type: "formula",
        ref: "assets/formula-1.svg",
        sources: [source],
      )
      expect(nvr.sources.size).to eq(1)
      expect(nvr.sources.first.type).to eq("authoritative")
    end
  end

  describe "YAML round-trip" do
    it "round-trips through YAML" do
      src = {
        "type" => "image",
        "ref" => "assets/images/figure-1.svg",
        "text" => "Diagram showing the concept",
        "sources" => [
          { "type" => "authoritative", "status" => "identical" },
        ],
      }.to_yaml

      nvr = described_class.from_yaml(src)
      expect(nvr.type).to eq("image")
      expect(nvr.ref).to eq("assets/images/figure-1.svg")
      expect(nvr.text).to eq("Diagram showing the concept")
      expect(nvr.sources.size).to eq(1)

      roundtrip = described_class.from_yaml(nvr.to_yaml)
      expect(roundtrip.type).to eq("image")
      expect(roundtrip.ref).to eq("assets/images/figure-1.svg")
      expect(roundtrip.text).to eq("Diagram showing the concept")
      expect(roundtrip.sources.size).to eq(1)
    end

    it "handles external URL references" do
      nvr = described_class.new(
        type: "image",
        ref: "https://example.org/images/figure-1.png",
      )
      roundtrip = described_class.from_yaml(nvr.to_yaml)
      expect(roundtrip.ref).to eq("https://example.org/images/figure-1.png")
    end

    it "handles URN references" do
      nvr = described_class.new(
        type: "table",
        ref: "urn:gcr:assets:table-103-01",
      )
      roundtrip = described_class.from_yaml(nvr.to_yaml)
      expect(roundtrip.ref).to eq("urn:gcr:assets:table-103-01")
    end
  end
end
