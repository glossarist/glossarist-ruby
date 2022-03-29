# frozen_string_literal: true

RSpec.describe Glossarist::Designation::LetterSymbol do
  subject { described_class.from_h(attributes) }

  let(:attributes) do
    {
      "type" => "letter_symbol",
      "designation" => "A",
      "international" => true,
      "text" => "A",
      "language" => "en",
      "script" => "Latn",
    }
  end

  describe "#to_h" do
    it "will convert letter symbol to hash" do
      expected_hash = {
        "type" => "letter_symbol",
        "designation" => "A",
        "international" => true,
        "text" => "A",
        "language" => "en",
        "script" => "Latn",
      }

      expect(subject.to_h).to eq(expected_hash)
    end
  end
end
