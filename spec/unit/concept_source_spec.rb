# frozen_string_literal: true

RSpec.describe Glossarist::ConceptSource do
  it_behaves_like "an Enum"

  subject { described_class.from_yaml(attributes) }

  let(:attributes) do
    {
      type: "authoritative",
      status: "identical",
      origin: { "id" => "123", "source" => "wikipedia",
                "version" => "Test version" },
      modification: "Test modification",
    }.to_yaml
  end

  describe "#to_yaml" do
    it "will convert concept source to hash" do
      expected_yaml = <<~YAML
        ---
        origin:
          ref:
            source: wikipedia
            id: '123'
            version: Test version
        status: identical
        type: authoritative
        modification: Test modification
      YAML

      expect(subject.to_yaml).to eq(expected_yaml)
    end
  end

  describe "#type" do
    it "returns type" do
      expect(subject.type).to eq("authoritative")
    end
  end

  describe "#status" do
    it "returns status" do
      expect(subject.status).to eq("identical")
    end
  end
end
