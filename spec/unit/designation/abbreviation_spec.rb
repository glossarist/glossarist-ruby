# frozen_string_literal: true

require_relative "../../support/shared_examples/enum"

RSpec.describe Glossarist::Designation::Abbreviation do
  subject { described_class.new(attributes) }

  let(:attributes) do
    {
      "acronym" => true,
      "designation" => "NASA",
      "international" => true,
    }
  end

  it_behaves_like "an Enum"

  describe "#to_h" do
    it "will convert abbreviation to hash" do
      expected_hash = {
        "type" => "acronym",
        "designation" => "NASA",
        "international" => true,
      }

      expect(subject.to_h).to eq(expected_hash)
    end
  end
end
