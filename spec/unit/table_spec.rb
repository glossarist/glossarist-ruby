# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Table do
  let(:table) do
    described_class.new(
      id: "unit-conversion",
      identifier: "Table 2",
      caption: { "eng" => "SI base units" },
      alt: { "eng" => "Table of SI base units with symbols and dimensions" },
      description: { "eng" => "Seven base units: metre, kilogram, second, ampere, kelvin, mole, candela" },
      content: { "headers" => %w[Unit Symbol Dimension], "rows" => [%w[meter m L]] },
      format: "structured",
    )
  end

  describe "YAML round-trip" do
    it "preserves all fields" do
      restored = described_class.from_yaml(table.to_yaml)
      expect(restored.id).to eq("unit-conversion")
      expect(restored.identifier).to eq("Table 2")
      expect(restored.caption["eng"]).to eq("SI base units")
      expect(restored.alt["eng"]).to include("SI base units")
      expect(restored.description["eng"]).to include("Seven base units")
      expect(restored.format).to eq("structured")
    end
  end

  describe "accessibility" do
    it "supports localized alt text" do
      expect(table.alt["eng"]).to include("Table of SI base units")
    end

    it "supports localized description for screen readers" do
      expect(table.description["eng"]).to include("Seven base units")
    end
  end

  it "inherits from NonVerbalEntity" do
    expect(table).to be_a(Glossarist::NonVerbalEntity)
  end
end
