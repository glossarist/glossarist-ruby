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
      retval = described_class.from_yaml(subject.to_yaml)

      expect(retval.type).to eq("letter_symbol")
      expect(retval.designation).to eq("A")
      expect(retval.international).to eq(true)
      expect(retval.text).to eq("A")
      expect(retval.language).to eq("en")
      expect(retval.script).to eq("Latn")
    end
  end
end
