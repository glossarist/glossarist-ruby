# frozen_string_literal: true

RSpec.describe Glossarist::Designation::LetterSymbol do
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
      expected_yaml = {
        "type" => "letter_symbol",
        "designation" => "A",
        "international" => true,
        "text" => "A",
        "language" => "en",
        "script" => "Latn",
      }

      expect(YAML.safe_load(subject.to_yaml)).to eq(expected_yaml)
    end
  end
end
