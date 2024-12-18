# frozen_string_literal: true

RSpec.describe Glossarist::NonVerbRep do
  let(:subject) { described_class.new }
  let(:attributes) do
    {
      type: "authoritative",
      status: "identical",
    }.to_yaml
  end

  let(:source) do
    Glossarist::ConceptSource.from_yaml(attributes)
  end

  describe "#image=" do
    it "sets the image" do
      subject.image = "image"
      expect(subject.image).to eq("image")
    end
  end

  describe "#table=" do
    it "sets the table" do
      subject.table = "table"
      expect(subject.table).to eq("table")
    end
  end

  describe "#formula=" do
    it "sets the formula" do
      subject.formula = "formula"
      expect(subject.formula).to eq("formula")
    end
  end

  describe "#sources=" do
    it "sets the sources" do
      subject.sources = [source]

      expected_yaml = <<~YAML
        ---
        status: identical
        type: authoritative
      YAML

      expect(subject.sources.size).to eq(1)
      expect(subject.sources.first.to_yaml).to eq(expected_yaml)
    end
  end
end
