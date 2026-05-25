# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::DomainTargetRule do
  subject(:rule) { described_class.new }

  def make_context(concept, concept_ids: Set.new)
    cc = instance_double(Glossarist::Validation::Rules::DatasetContext)
    allow(cc).to receive(:concept_ids).and_return(concept_ids)
    Glossarist::Validation::Rules::ConceptContext.new(
      concept, file_name: "test.yaml", collection_context: cc
    )
  end

  describe "#code" do
    it { expect(rule.code).to eq("GLS-111") }
  end

  describe "#check" do
    it "passes for local domain ref that exists" do
      domain = Glossarist::ConceptReference.new(concept_id: "section-3-1")
      data = instance_double(Glossarist::ManagedConceptData, domains: [domain])
      concept = instance_double(Glossarist::ManagedConcept, data: data)
      allow(data).to receive(:domains).and_return([domain])

      issues = rule.check(make_context(concept, concept_ids: Set.new(["section-3-1"])))
      expect(issues).to be_empty
    end

    it "flags local domain ref not in dataset" do
      domain = Glossarist::ConceptReference.new(concept_id: "nonexistent")
      data = instance_double(Glossarist::ManagedConceptData, domains: [domain])
      concept = instance_double(Glossarist::ManagedConcept, data: data)
      allow(data).to receive(:domains).and_return([domain])

      issues = rule.check(make_context(concept, concept_ids: Set.new(["section-3-1"])))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("not in dataset")
    end

    it "passes for URN domain" do
      domain = Glossarist::ConceptReference.new(
        concept_id: "section-3-1",
        source: "urn:iso:std:iso:ts:14812",
      )
      data = instance_double(Glossarist::ManagedConceptData, domains: [domain])
      concept = instance_double(Glossarist::ManagedConcept, data: data)
      allow(data).to receive(:domains).and_return([domain])

      issues = rule.check(make_context(concept, concept_ids: Set.new))
      expect(issues).to be_empty
    end

    it "flags invalid URN" do
      domain = Glossarist::ConceptReference.new(urn: "urn:invalid urn!!!")
      data = instance_double(Glossarist::ManagedConceptData, domains: [domain])
      concept = instance_double(Glossarist::ManagedConcept, data: data)
      allow(data).to receive(:domains).and_return([domain])

      issues = rule.check(make_context(concept, concept_ids: Set.new))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("invalid URN")
    end
  end
end
