# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::NonVerbRep do
  let(:source) do
    Glossarist::ConceptSource.from_yaml({
      "type" => "authoritative",
      "status" => "identical",
    }.to_yaml)
  end

  describe "inheritance" do
    it "is a NonVerbalEntity" do
      expect(described_class).to be < Glossarist::NonVerbalEntity
    end

    it "is NOT a SharedNonVerbalEntity (no dataset identity)" do
      expect(described_class).not_to be < Glossarist::SharedNonVerbalEntity
    end
  end

  describe "attributes" do
    it "declares type and images on top of the shared payload" do
      keys = described_class.attributes.keys
      expect(keys).to include(:type, :images, :caption, :description, :alt,
                              :sources)
    end

    it "does not declare ref or text (legacy fields removed)" do
      keys = described_class.attributes.keys
      expect(keys).not_to include(:ref)
      expect(keys).not_to include(:text)
    end

    it "does not carry dataset identity (id, identifier)" do
      keys = described_class.attributes.keys
      expect(keys).not_to include(:id)
      expect(keys).not_to include(:identifier)
    end
  end

  describe "type" do
    it "accepts image, table, or formula" do
      %w[image table formula].each do |t|
        nvr = described_class.new(type: t)
        expect(nvr.type).to eq(t)
      end
    end
  end

  describe "images" do
    it "accepts a collection of FigureImage variants" do
      svg = Glossarist::FigureImage.new(src: "assets/diagram.svg",
                                        format: "svg", role: "vector")
      png = Glossarist::FigureImage.new(src: "assets/diagram.png",
                                        format: "png", role: "raster")
      nvr = described_class.new(type: "image", images: [svg, png])
      expect(nvr.images.size).to eq(2)
      expect(nvr.images.first.src).to eq("assets/diagram.svg")
      expect(nvr.images.last.format).to eq("png")
    end

    it "defaults to an empty collection" do
      expect(described_class.new.images).to be_empty
    end
  end

  describe "localized accessibility fields (inherited)" do
    it "supports localized alt" do
      nvr = described_class.new(alt: { "eng" => "Diagram of a sensor",
                                       "fra" => "Diagramme d'un capteur" })
      expect(nvr.alt["eng"]).to eq("Diagram of a sensor")
      expect(nvr.alt["fra"]).to eq("Diagramme d'un capteur")
    end

    it "supports localized caption" do
      nvr = described_class.new(caption: { "eng" => "Sensor diagram" })
      expect(nvr.caption["eng"]).to eq("Sensor diagram")
    end

    it "supports localized description" do
      nvr = described_class.new(description: { "eng" => "Long description..." })
      expect(nvr.description["eng"]).to eq("Long description...")
    end
  end

  describe "sources" do
    it "accepts a ConceptSource collection" do
      nvr = described_class.new(type: "formula", sources: [source])
      expect(nvr.sources.size).to eq(1)
      expect(nvr.sources.first.type).to eq("authoritative")
    end
  end

  describe "YAML round-trip" do
    let(:yaml) do
      <<~YAML
        ---
        type: image
        images:
        - src: assets/images/figure-1.svg
          format: svg
          role: vector
        - src: assets/images/figure-1.png
          format: png
          role: raster
        caption:
          eng: Sensor diagram
          fra: Diagramme du capteur
        description:
          eng: Long description of the diagram
        alt:
          eng: Diagram of a sensor
        sources:
        - type: authoritative
          status: identical
      YAML
    end

    it "round-trips through YAML" do
      nvr = described_class.from_yaml(yaml)
      expect(nvr.type).to eq("image")
      expect(nvr.images.size).to eq(2)
      expect(nvr.images.first.src).to eq("assets/images/figure-1.svg")
      expect(nvr.images.first.format).to eq("svg")
      expect(nvr.images.last.src).to eq("assets/images/figure-1.png")
      expect(nvr.caption["eng"]).to eq("Sensor diagram")
      expect(nvr.caption["fra"]).to eq("Diagramme du capteur")
      expect(nvr.description["eng"]).to eq("Long description of the diagram")
      expect(nvr.alt["eng"]).to eq("Diagram of a sensor")
      expect(nvr.sources.size).to eq(1)

      roundtrip = described_class.from_yaml(nvr.to_yaml)
      expect(roundtrip.type).to eq("image")
      expect(roundtrip.images.size).to eq(2)
      expect(roundtrip.images.map(&:src)).to contain_exactly(
        "assets/images/figure-1.svg",
        "assets/images/figure-1.png",
      )
      expect(roundtrip.caption["fra"]).to eq("Diagramme du capteur")
      expect(roundtrip.alt["eng"]).to eq("Diagram of a sensor")
      expect(roundtrip.sources.size).to eq(1)
    end

    it "handles external URL references as image src" do
      nvr = described_class.new(
        type: "image",
        images: [Glossarist::FigureImage.new(
          src: "https://example.org/images/figure-1.png",
        )],
      )
      roundtrip = described_class.from_yaml(nvr.to_yaml)
      expect(roundtrip.images.first.src).to eq(
        "https://example.org/images/figure-1.png",
      )
    end

    it "handles URN references as image src" do
      nvr = described_class.new(
        type: "table",
        images: [Glossarist::FigureImage.new(
          src: "urn:gcr:assets:table-103-01",
        )],
      )
      roundtrip = described_class.from_yaml(nvr.to_yaml)
      expect(roundtrip.images.first.src).to eq("urn:gcr:assets:table-103-01")
    end
  end
end
