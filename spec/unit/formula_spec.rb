# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Formula do
  let(:formula) do
    described_class.new(
      id: "wave-equation",
      identifier: "Equation 1",
      caption: { "eng" => "Electromagnetic wave equation" },
      alt: { "eng" => "Second-order partial differential equation for E-field" },
      description: { "eng" => "Describes wave propagation in free space" },
      expression: { "eng" => "\\nabla^2 \\mathbf{E} = \\mu_0 \\epsilon_0 \\frac{\\partial^2 \\mathbf{E}}{\\partial t^2}" },
      notation: "latex",
    )
  end

  describe "YAML round-trip" do
    it "preserves all fields" do
      restored = described_class.from_yaml(formula.to_yaml)
      expect(restored.id).to eq("wave-equation")
      expect(restored.identifier).to eq("Equation 1")
      expect(restored.caption["eng"]).to eq("Electromagnetic wave equation")
      expect(restored.notation).to eq("latex")
    end
  end

  describe "accessibility" do
    it "supports localized alt text" do
      expect(formula.alt["eng"]).to include("Second-order partial differential")
    end

    it "supports localized description for screen readers" do
      expect(formula.description["eng"]).to include("wave propagation")
    end
  end

  it "inherits from NonVerbalEntity" do
    expect(formula).to be_a(Glossarist::NonVerbalEntity)
  end
end
