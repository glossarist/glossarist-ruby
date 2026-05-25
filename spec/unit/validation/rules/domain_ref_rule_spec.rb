# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::DomainRefRule do
  subject(:rule) { described_class.new }

  def make_context(concept)
    Glossarist::Validation::Rules::ConceptContext.new(
      concept, file_name: "test.yaml", collection_context: nil
    )
  end

  describe "#code" do
    it { expect(rule.code).to eq("GLS-309") }
  end

  describe "#check" do
    it "passes for domain with concept_id" do
      domain = Glossarist::ConceptReference.new(concept_id: "section-3-1")
      data = instance_double(Glossarist::ManagedConceptData, domains: [domain])
      concept = instance_double(Glossarist::ManagedConcept, data: data)
      allow(data).to receive(:domains).and_return([domain])

      issues = rule.check(make_context(concept))
      expect(issues).to be_empty
    end

    it "passes for domain with urn" do
      domain = Glossarist::ConceptReference.new(urn: "urn:iso:std:iso:ts:14812")
      data = instance_double(Glossarist::ManagedConceptData, domains: [domain])

      concept = instance_double(Glossarist::ManagedConcept, data: data)
      allow(data).to receive(:domains).and_return([domain])

      issues = rule.check(make_context(concept))
      expect(issues).to be_empty
    end

    it "flags domain with neither concept_id nor urn" do
      domain = Glossarist::ConceptReference.new(source: "ISO")
      data = instance_double(Glossarist::ManagedConceptData, domains: [domain])
      concept = instance_double(Glossarist::ManagedConcept, data: data)
      allow(data).to receive(:domains).and_return([domain])

      issues = rule.check(make_context(concept))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("neither concept_id nor urn")
    end
  end
end
