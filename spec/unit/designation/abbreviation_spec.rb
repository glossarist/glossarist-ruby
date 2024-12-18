# frozen_string_literal: true

require_relative "../../support/shared_examples/enum"

RSpec.describe Glossarist::Designation::Abbreviation do
  subject { described_class.from_yaml(attributes) }

  let(:attributes) do
    {
      "acronym" => true,
      "designation" => "NASA",
      "international" => true,
    }.to_yaml
  end

  it_behaves_like "an Enum"

  describe "#to_yaml" do
    it "will convert abbreviation to yaml" do
      expected_yaml = {
        "type" => "abbreviation",
        "designation" => "NASA",
        "acronym" => true,
        "international" => true,
      }

      expect(YAML.load(subject.to_yaml)).to eq(expected_yaml)
    end
  end
end
