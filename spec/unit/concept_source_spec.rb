# frozen_string_literal: true

RSpec.describe Glossarist::ConceptSource do
  it_behaves_like "an Enum"

  subject { described_class.new(attributes) }

  let(:attributes) do
    {
      type: "authoritative",
      status: "identical",
      origin: { "id"=> "123", "source" => "wikipedia", "version" => "Test version"},
      modification: "Test modification",
    }
  end

  describe "#to_h" do
    it "will convert concept source to hash" do
      expected_hash = {
        "type" => "authoritative",
        "status" => "identical",
        "origin" => { "ref" => {"id"=> "123", "source" => "wikipedia", "version" => "Test version" } },
        "modification" => "Test modification",
      }

      expect(subject.to_h).to eq(expected_hash)
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
