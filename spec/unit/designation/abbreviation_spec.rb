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
      retval = described_class.from_yaml(subject.to_yaml)

      expect(retval.type).to eq("abbreviation")
      expect(retval.designation).to eq("NASA")
      expect(retval.acronym).to eq(true)
      expect(retval.international).to eq(true)
    end
  end
end
