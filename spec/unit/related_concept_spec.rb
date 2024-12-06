# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::LutamlModel::RelatedConcept do
  # it_behaves_like "an Enum"

  subject { described_class.from_yaml(attributes) }
  let(:attributes) do
    {
      content: "Test content",
      type: :supersedes,
      ref: {
        source: "Test source",
        id: "Test id",
        version: "Test version",
      }
    }.to_yaml
  end

  describe "#to_yaml" do
    it "will convert related concept to yaml" do
      expected_yaml = <<~YAML
        ---
        content: Test content
        type: supersedes
        ref:
          source: Test source
          id: Test id
          version: Test version
      YAML

      expect(subject.to_yaml).to eq(expected_yaml)
    end
  end
end
