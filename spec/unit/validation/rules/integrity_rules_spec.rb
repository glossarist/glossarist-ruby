# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Integrity rules" do
  describe Glossarist::Validation::Rules::ConceptCountRule do
    subject(:rule) { described_class.new }

    it "flags when concept_count doesn't match actual count" do
      metadata = Glossarist::GcrMetadata.new(
        shortname: "test", version: "1.0.0",
        concept_count: 5, languages: ["eng"], schema_version: "1"
      )
      ctx = instance_double(Glossarist::Validation::Rules::GcrContext,
                            metadata: metadata, concepts: [double, double], gcr?: true)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-011")
    end

    it "passes when concept_count matches" do
      metadata = Glossarist::GcrMetadata.new(
        shortname: "test", version: "1.0.0",
        concept_count: 2, languages: ["eng"], schema_version: "1"
      )
      ctx = instance_double(Glossarist::Validation::Rules::GcrContext,
                            metadata: metadata, concepts: [double, double], gcr?: true)
      expect(rule.check(ctx)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::ConceptUriRule do
    subject(:rule) { described_class.new }

    it "warns when no uri_prefix in metadata" do
      metadata = Glossarist::GcrMetadata.new(
        shortname: "test", version: "1.0.0",
        concept_count: 1, languages: ["eng"], schema_version: "1"
      )
      ctx = instance_double(Glossarist::Validation::Rules::GcrContext,
                            metadata: metadata, gcr?: true)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.message).to include("no concept URI")
    end

    it "passes when uri_prefix is set" do
      metadata = Glossarist::GcrMetadata.new(
        shortname: "test", version: "1.0.0",
        concept_count: 1, languages: ["eng"], schema_version: "1",
        uri_prefix: "urn:test"
      )
      ctx = instance_double(Glossarist::Validation::Rules::GcrContext,
                            metadata: metadata, gcr?: true)
      expect(rule.check(ctx)).to be_empty
    end
  end
end
