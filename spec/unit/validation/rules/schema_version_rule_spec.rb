# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::SchemaVersionRule do
  subject(:rule) { described_class.new }

  let(:concept) { instance_double(Glossarist::ManagedConcept) }

  def make_context(concept)
    Glossarist::Validation::Rules::ConceptContext.new(
      concept, file_name: "test.yaml", collection_context: nil
    )
  end

  describe "#code" do
    it { expect(rule.code).to eq("GLS-010") }
  end

  describe "#category" do
    it { expect(rule.category).to eq(:schema) }
  end

  describe "#severity" do
    it { expect(rule.severity).to eq("warning") }
  end

  describe "#scope" do
    it { expect(rule.scope).to eq(:concept) }
  end

  describe "#applicable?" do
    it "returns true when concept is a ManagedConcept" do
      mc = Glossarist::ManagedConcept.new
      expect(rule.applicable?(make_context(mc))).to be true
    end

    it "returns false when concept is not a ManagedConcept" do
      concept = instance_double(Glossarist::LocalizedConcept)
      expect(rule.applicable?(make_context(concept))).to be false
    end
  end

  describe "#check" do
    it "passes for schema_version 3" do
      mc = Glossarist::ManagedConcept.new
      mc.schema_version = "3"
      issues = rule.check(make_context(mc))
      expect(issues).to be_empty
    end

    it "flags missing schema_version" do
      mc = Glossarist::ManagedConcept.new
      issues = rule.check(make_context(mc))
      expect(issues.size).to eq(1)
      expect(issues.first.code).to eq("GLS-010")
      expect(issues.first.message).to include("no schema_version")
    end

    it "flags wrong schema_version" do
      mc = Glossarist::ManagedConcept.new
      mc.schema_version = "2"
      issues = rule.check(make_context(mc))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("expected '3'")
    end

    it "flags blank schema_version" do
      mc = Glossarist::ManagedConcept.new
      mc.schema_version = ""
      issues = rule.check(make_context(mc))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("no schema_version")
    end
  end
end
