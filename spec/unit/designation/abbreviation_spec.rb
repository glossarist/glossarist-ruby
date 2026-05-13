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

  describe "#international" do
    it "is inherited from Base" do
      expect(subject.international).to eq(true)
    end

    it "round-trips through YAML" do
      roundtrip = described_class.from_yaml(subject.to_yaml)
      expect(roundtrip.international).to eq(true)
    end
  end

  describe "#absent" do
    it "is inherited from Base" do
      abbr = described_class.from_yaml({
        "designation" => "N/A",
        "absent" => true,
        "acronym" => true,
      }.to_yaml)
      expect(abbr.absent).to eq(true)
    end
  end

  describe "#field_of_application" do
    it "is inherited from Expression" do
      abbr = described_class.from_yaml({
        "designation" => "N/A",
        "field_of_application" => "in computing",
        "acronym" => true,
      }.to_yaml)
      expect(abbr.field_of_application).to eq("in computing")
    end
  end

  describe "#term_type" do
    it "accepts ISO 12620 term type" do
      abbr = described_class.new(designation: "WWW", acronym: true,
                                 term_type: "acronym")
      expect(abbr.term_type).to eq("acronym")
    end

    it "round-trips through YAML" do
      abbr = described_class.from_yaml({
        "designation" => "WWW",
        "acronym" => true,
        "term_type" => "acronym",
      }.to_yaml)
      expect(abbr.term_type).to eq("acronym")

      roundtrip = described_class.from_yaml(abbr.to_yaml)
      expect(roundtrip.term_type).to eq("acronym")
    end
  end

  describe "#related" do
    it "accepts designation-level relationships" do
      abbr = described_class.new(designation: "WWW", acronym: true)
      abbr.related = [
        Glossarist::RelatedConcept.new(type: "abbreviated_form_for",
                                       content: "World Wide Web"),
      ]
      expect(abbr.related.first.type).to eq("abbreviated_form_for")
      expect(abbr.related.first.content).to eq("World Wide Web")
    end
  end
end
