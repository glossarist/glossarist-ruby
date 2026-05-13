# frozen_string_literal: true

RSpec.describe Glossarist::Designation::GraphicalSymbol do
  subject { described_class.from_yaml(attributes) }

  let(:attributes) do
    {
      "type" => "graphical_symbol",
      "image" => "♔",
      "text" => "king",
      "international" => true,
    }.to_yaml
  end

  describe "#to_yaml" do
    it "will convert graphical symbol to yaml" do
      expected_yaml = <<~YAML
        ---
        type: graphical_symbol
        international: true
        text: king
        image: "♔"
      YAML

      expect(subject.to_yaml).to eq(expected_yaml)
    end
  end

  describe "#international" do
    it "is inherited from Base" do
      expect(subject.international).to eq(true)
    end
  end

  describe "#absent" do
    it "is inherited from Base" do
      gs = described_class.from_yaml({
        "type" => "graphical_symbol",
        "image" => "♔",
        "absent" => true,
      }.to_yaml)
      expect(gs.absent).to eq(true)
    end
  end
end
