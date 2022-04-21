# frozen_string_literal: true

RSpec.describe Glossarist::NonVerbRep do
  let(:subject) { described_class.new }

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
      subject.sources = [{
        type: "authoritative",
        status: "identical",
      }]

      expected_hash = {
        "type" => "authoritative",
        "status" => "identical",
      }

      expect(subject.sources.size).to eq(1)
      expect(subject.sources.first.to_h).to eq(expected_hash)
    end
  end
end
