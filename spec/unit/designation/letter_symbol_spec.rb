# frozen_string_literal: true

RSpec.describe Glossarist::LutamlModel::LetterSymbol do
  subject { described_class.from_yaml(attributes) }

  let(:attributes) do
    {
      "type" => "letter_symbol",
      "designation" => "A",
      "international" => true,
      "text" => "A",
      "language" => "en",
      "script" => "Latn",
  }.to_yaml
  end

  describe "#to_yaml" do
    it "will convert letter symbol to yaml" do
      expected_yaml = <<~YAML
        ---
        designation: A
        type: letter_symbol
        international: 'true'
        text: A
        language: en
        script: Latn
      YAML

      expect(subject.to_yaml).to eq(expected_yaml)
    end
  end
end
