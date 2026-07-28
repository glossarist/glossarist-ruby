# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::Multiplicity do
  describe "constants (derived from NAME_BY_PAIR)" do
    it "freezes NAME_BY_PAIR" do
      expect(described_class::NAME_BY_PAIR).to be_frozen
    end

    it "lists the 5 valid ISO 704 combinations in NAME_BY_PAIR" do
      pairs = described_class::NAME_BY_PAIR.keys
      expect(pairs).to contain_exactly(
        %w[required exactly_one],
        %w[optional exactly_one],
        %w[required multiple],
        %w[optional multiple],
        %w[required at_least_one],
      )
    end

    it "maps each pair to the expected ISO 704 name" do
      expect(described_class::NAME_BY_PAIR[%w[required exactly_one]])
        .to eq("compulsory")
      expect(described_class::NAME_BY_PAIR[%w[optional exactly_one]])
        .to eq("optional")
      expect(described_class::NAME_BY_PAIR[%w[required multiple]])
        .to eq("compulsory_multiple")
      expect(described_class::NAME_BY_PAIR[%w[optional multiple]])
        .to eq("optional_multiple")
      expect(described_class::NAME_BY_PAIR[%w[required at_least_one]])
        .to eq("compulsory_at_least_one")
    end

    it "derives MULTIPLICITY uppercase keys from NAME_BY_PAIR values" do
      expect(described_class::MULTIPLICITY).to eq(
        COMPULSORY: "compulsory",
        OPTIONAL: "optional",
        COMPULSORY_MULTIPLE: "compulsory_multiple",
        OPTIONAL_MULTIPLE: "optional_multiple",
        COMPULSORY_AT_LEAST_ONE: "compulsory_at_least_one",
      )
      expect(described_class::MULTIPLICITY).to be_frozen
    end

    it "derives MULTIPLICITY_VALUES from NAME_BY_PAIR values" do
      expect(described_class::MULTIPLICITY_VALUES).to contain_exactly(
        "compulsory",
        "optional",
        "compulsory_multiple",
        "optional_multiple",
        "compulsory_at_least_one",
      )
      expect(described_class::MULTIPLICITY_VALUES).to be_frozen
    end

    it "defaults DEFAULT_MULTIPLICITY to compulsory" do
      expect(described_class::DEFAULT_MULTIPLICITY).to eq("compulsory")
    end
  end

  describe ".multiplicity_from_pair" do
    it "returns the ISO 704 name for each valid combination" do
      expect(described_class.multiplicity_from_pair("required", "exactly_one"))
        .to eq("compulsory")
      expect(described_class.multiplicity_from_pair("optional", "exactly_one"))
        .to eq("optional")
      expect(described_class.multiplicity_from_pair("required", "multiple"))
        .to eq("compulsory_multiple")
      expect(described_class.multiplicity_from_pair("optional", "multiple"))
        .to eq("optional_multiple")
      expect(described_class.multiplicity_from_pair("required", "at_least_one"))
        .to eq("compulsory_at_least_one")
    end

    it "raises ArgumentError on the invalid optional + at_least_one combo" do
      expect { described_class.multiplicity_from_pair("optional", "at_least_one") }
        .to raise_error(
          ArgumentError,
          /Invalid multiplicity combination: presence=optional, count=at_least_one/,
        )
    end

    it "raises ArgumentError on an unknown presence value" do
      expect { described_class.multiplicity_from_pair("mandatory", "exactly_one") }
        .to raise_error(ArgumentError, /Invalid multiplicity combination/)
    end

    it "raises ArgumentError on an unknown count value" do
      expect { described_class.multiplicity_from_pair("required", "many") }
        .to raise_error(ArgumentError, /Invalid multiplicity combination/)
    end
  end

  describe ".pair_from_multiplicity" do
    it "returns the (presence, count) hash for each valid name" do
      expect(described_class.pair_from_multiplicity("compulsory"))
        .to eq(presence: "required", count: "exactly_one")
      expect(described_class.pair_from_multiplicity("optional"))
        .to eq(presence: "optional", count: "exactly_one")
      expect(described_class.pair_from_multiplicity("compulsory_multiple"))
        .to eq(presence: "required", count: "multiple")
      expect(described_class.pair_from_multiplicity("optional_multiple"))
        .to eq(presence: "optional", count: "multiple")
      expect(described_class.pair_from_multiplicity("compulsory_at_least_one"))
        .to eq(presence: "required", count: "at_least_one")
    end

    it "raises ArgumentError on an unknown name" do
      expect { described_class.pair_from_multiplicity("bogus") }
        .to raise_error(ArgumentError, /Unknown multiplicity: "bogus"/)
    end
  end

  describe ".valid_multiplicity?" do
    it "is true for each valid name" do
      %w[compulsory optional compulsory_multiple optional_multiple
         compulsory_at_least_one].each do |name|
        expect(described_class.valid_multiplicity?(name)).to be(true), name
      end
    end

    it "is false for an unknown name" do
      expect(described_class.valid_multiplicity?("bogus")).to be(false)
    end

    it "is false for the raw dimensions (not ISO names)" do
      expect(described_class.valid_multiplicity?("required")).to be(false)
      expect(described_class.valid_multiplicity?("exactly_one")).to be(false)
    end
  end

  describe ".invalid_combination_error" do
    it "returns an ArgumentError instance (not the array tuple form)" do
      err = described_class.invalid_combination_error("optional", "at_least_one")
      expect(err).to be_a(ArgumentError)
      expect(err).not_to be_a(Array)
    end

    it "includes the presence and count values in the message" do
      err = described_class.invalid_combination_error("optional", "at_least_one")
      expect(err.message).to include("presence=optional")
      expect(err.message).to include("count=at_least_one")
    end

    it "explains why optional + at_least_one is invalid" do
      err = described_class.invalid_combination_error("optional", "at_least_one")
      expect(err.message)
        .to include("optional + at_least_one collapses to optional + multiple")
    end
  end
end
