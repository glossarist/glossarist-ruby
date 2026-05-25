# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::UuidFormatRule do
  subject(:rule) { described_class.new }

  def make_context(concept)
    Glossarist::Validation::Rules::ConceptContext.new(
      concept, file_name: "test.yaml", collection_context: nil
    )
  end

  describe "#code" do
    it { expect(rule.code).to eq("GLS-016") }
  end

  describe "#check" do
    it "passes for valid UUID" do
      concept = instance_double(Glossarist::ManagedConcept,
                                uuid: "0ce27901-02ce-531e-8ba5-fdb136139d1a")
      issues = rule.check(make_context(concept))
      expect(issues).to be_empty
    end

    it "passes for nil UUID" do
      concept = instance_double(Glossarist::ManagedConcept, uuid: nil)
      issues = rule.check(make_context(concept))
      expect(issues).to be_empty
    end

    it "flags invalid UUID format" do
      concept = instance_double(Glossarist::ManagedConcept, uuid: "not-a-uuid")
      issues = rule.check(make_context(concept))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("not valid UUID format")
    end

    it "flags numeric-only UUID" do
      concept = instance_double(Glossarist::ManagedConcept, uuid: "12345")
      issues = rule.check(make_context(concept))
      expect(issues.size).to eq(1)
    end
  end
end
