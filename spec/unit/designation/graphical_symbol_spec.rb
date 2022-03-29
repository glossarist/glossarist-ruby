# frozen_string_literal: true

RSpec.describe Glossarist::Designation::GraphicalSymbol do
  subject { described_class.from_h(attributes) }

  let(:attributes) do
    {
      "type" => "graphical_symbol",
      "image" => "♔",
      "text" => "king",
      "international" => true,
    }
  end

  describe "#to_h" do
    it "will convert graphical symbol to hash" do
      expected_hash = {
        "type" => "graphical_symbol",
        "image" => "♔",
        "text" => "king",
        "international" => true,
      }

      expect(subject.to_h).to eq(expected_hash)
    end
  end
end
