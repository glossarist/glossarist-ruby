# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::RelatedConcept do
  it_behaves_like "an Enum"

  subject { described_class.new(attributes) }
  let(:attributes) do
    {
      content: "Test content",
      type: :supersedes,
      ref: {
        source: "Test source",
        id: "Test id",
        version: "Test version",
      }
    }
  end

  describe "#to_h" do
    it "will convert related concept to hash" do
      expected_hash = {
        "content" => "Test content",
        "type" => "supersedes",
        "ref" => {
          "source" => "Test source",
          "id" => "Test id",
          "version" => "Test version",
        },
      }

      expect(subject.to_h).to eq(expected_hash)
    end
  end
end
