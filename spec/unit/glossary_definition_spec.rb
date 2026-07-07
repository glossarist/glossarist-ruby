# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::GlossaryDefinition do
  # GlossaryDefinition is a module of frozen constants derived from
  # config.yml. The SSOT contract: each constant must exist, be an Array
  # of strings, and be frozen. If config.yml renames a key or moves,
  # these specs fail loudly — surfacing the regression here rather than
  # in some downstream gem that consumes glossarist-ruby.

  described_class.constants.each do |name|
    value = described_class.const_get(name)

    it "#{name} is frozen" do
      expect(value).to be_frozen, "#{name} should be frozen"
    end
  end

  describe "config-derived enum constants" do
    it "CONCEPT_SOURCE_STATUSES is a non-empty Array of strings" do
      v = described_class::CONCEPT_SOURCE_STATUSES
      expect(v).to be_an(Array)
      expect(v).not_to be_empty
      expect(v).to all(be_a(String))
    end

    it "CONCEPT_SOURCE_TYPES is a non-empty Array of strings" do
      v = described_class::CONCEPT_SOURCE_TYPES
      expect(v).to be_an(Array)
      expect(v).not_to be_empty
      expect(v).to all(be_a(String))
    end

    it "RELATED_CONCEPT_TYPES is a non-empty Array of strings" do
      v = described_class::RELATED_CONCEPT_TYPES
      expect(v).to be_an(Array)
      expect(v).not_to be_empty
      expect(v).to all(be_a(String))
    end

    it "DESIGNATION_BASE_NORMATIVE_STATUSES includes preferred/admitted/deprecated/superseded" do
      v = described_class::DESIGNATION_BASE_NORMATIVE_STATUSES
      %w[preferred admitted deprecated superseded].each do |status|
        expect(v).to include(status),
                     "expected #{status} in DESIGNATION_BASE_NORMATIVE_STATUSES"
      end
    end

    it "CONCEPT_STATUSES is a non-empty Array of strings" do
      v = described_class::CONCEPT_STATUSES
      expect(v).to be_an(Array)
      expect(v).not_to be_empty
      expect(v).to all(be_a(String))
    end

    it "CONCEPT_DATE_TYPES is a non-empty Array of strings" do
      v = described_class::CONCEPT_DATE_TYPES
      expect(v).to be_an(Array)
      expect(v).to all(be_a(String))
    end

    it "GRAMMAR_INFO_BOOLEAN_ATTRIBUTES is a non-empty Array" do
      v = described_class::GRAMMAR_INFO_BOOLEAN_ATTRIBUTES
      expect(v).to be_an(Array)
      expect(v).not_to be_empty
    end

    it "GRAMMAR_INFO_GENDERS is an Array of strings" do
      v = described_class::GRAMMAR_INFO_GENDERS
      expect(v).to be_an(Array)
      expect(v).to all(be_a(String))
    end

    it "GRAMMAR_INFO_NUMBERS is an Array of strings" do
      v = described_class::GRAMMAR_INFO_NUMBERS
      expect(v).to be_an(Array)
      expect(v).to all(be_a(String))
    end

    it "ISO12620_TERM_TYPES is an Array of strings" do
      v = described_class::ISO12620_TERM_TYPES
      expect(v).to be_an(Array)
      expect(v).to all(be_a(String))
    end
  end
end
