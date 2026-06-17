# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Figure do
  let(:figure) do
    described_class.new(
      id: "mixed-reflection",
      identifier: "Figure 7c",
      caption: { "eng" => "Mixed reflection", "fra" => "Réflexion mixte" },
      alt: { "eng" => "Diagram showing reflection" },
      images: [
        Glossarist::FigureImage.new(src: "fig.svg", format: "svg", role: "vector"),
        Glossarist::FigureImage.new(src: "fig.png", format: "png", role: "raster",
                                    width: 1600, height: 1200),
      ],
      sources: [
        Glossarist::ConceptSource.new(
          type: "authoritative",
          origin: Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(source: "ISO")),
        ),
      ],
    )
  end

  describe "YAML round-trip" do
    it "preserves all fields" do
      yaml = figure.to_yaml
      restored = described_class.from_yaml(yaml)

      expect(restored.id).to eq("mixed-reflection")
      expect(restored.identifier).to eq("Figure 7c")
      expect(restored.caption["eng"]).to eq("Mixed reflection")
      expect(restored.caption["fra"]).to eq("Réflexion mixte")
      expect(restored.alt["eng"]).to eq("Diagram showing reflection")
      expect(restored.images.length).to eq(2)
      expect(restored.images[0].src).to eq("fig.svg")
      expect(restored.images[0].format).to eq("svg")
      expect(restored.images[1].width).to eq(1600)
      expect(restored.sources.first.type).to eq("authoritative")
    end

    it "handles nil optional fields" do
      minimal = described_class.new(
        id: "minimal",
        alt: { "eng" => "Minimal" },
        images: [Glossarist::FigureImage.new(src: "m.svg", format: "svg")],
      )
      restored = described_class.from_yaml(minimal.to_yaml)
      expect(restored.identifier).to be_nil
      expect(restored.caption).to be_nil.or be_empty
      expect(Array(restored.subfigures)).to be_empty
    end
  end

  describe "subfigures (recursive)" do
    let(:composite) do
      described_class.new(
        id: "composite",
        images: [Glossarist::FigureImage.new(src: "c.svg", format: "svg")],
        subfigures: [
          described_class.new(
            id: "sub-a",
            images: [Glossarist::FigureImage.new(src: "a.svg", format: "svg")],
          ),
          described_class.new(
            id: "sub-b",
            images: [Glossarist::FigureImage.new(src: "b.svg", format: "svg")],
            subfigures: [
              described_class.new(
                id: "sub-b-1",
                images: [Glossarist::FigureImage.new(src: "b1.svg", format: "svg")],
              ),
            ],
          ),
        ],
      )
    end

    it "round-trips recursive subfigures" do
      restored = described_class.from_yaml(composite.to_yaml)
      expect(restored.subfigures.length).to eq(2)
      expect(restored.subfigures[0].id).to eq("sub-a")
      expect(restored.subfigures[1].subfigures[0].id).to eq("sub-b-1")
    end

    it "finds nested subfigure by id" do
      expect(composite.find_by_id("composite")).to eq(composite)
      expect(composite.find_by_id("sub-a")&.id).to eq("sub-a")
      expect(composite.find_by_id("sub-b-1")&.id).to eq("sub-b-1")
      expect(composite.find_by_id("nonexistent")).to be_nil
    end

    it "collects all ids recursively" do
      expect(composite.all_ids).to contain_exactly("composite", "sub-a", "sub-b", "sub-b-1")
    end
  end

  describe "accessibility" do
    it "supports localized alt text" do
      expect(figure.alt["eng"]).to eq("Diagram showing reflection")
    end

    it "supports localized description" do
      figure.description = { "eng" => "Long description for screen readers" }
      expect(figure.description["eng"]).to eq("Long description for screen readers")
    end
  end
end
