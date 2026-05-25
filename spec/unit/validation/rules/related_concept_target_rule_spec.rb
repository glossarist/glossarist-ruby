# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::RelatedConceptTargetRule do
  subject(:rule) { described_class.new }

  def make_context(concept, concept_ids: Set.new)
    cc = instance_double(Glossarist::Validation::Rules::DatasetContext)
    allow(cc).to receive(:concept_ids).and_return(concept_ids)
    Glossarist::Validation::Rules::ConceptContext.new(
      concept, file_name: "test.yaml", collection_context: cc
    )
  end

  describe "#code" do
    it { expect(rule.code).to eq("GLS-110") }
  end

  describe "#check" do
    it "passes when related concept target exists in dataset" do
      ref = Glossarist::ConceptRef.new(id: "3.1.3.9")
      related = [Glossarist::RelatedConcept.new(content: "test", type: "broader", ref: ref)]
      concept = instance_double(Glossarist::ManagedConcept, related: related)

      issues = rule.check(make_context(concept, concept_ids: Set.new(["3.1.3.9"])))
      expect(issues).to be_empty
    end

    it "flags local ref to non-existent concept" do
      ref = Glossarist::ConceptRef.new(id: "9.9.9.9")
      related = [Glossarist::RelatedConcept.new(content: "test", type: "broader", ref: ref)]
      concept = instance_double(Glossarist::ManagedConcept, related: related)

      issues = rule.check(make_context(concept, concept_ids: Set.new(["3.1.3.9"])))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("not in the dataset")
    end

    it "passes for external ref with valid URN" do
      ref = Glossarist::ConceptRef.new(source: "urn:iso:std:iso:ts:14812", id: "section-3-1")
      related = [Glossarist::RelatedConcept.new(content: "test", type: "broader", ref: ref)]
      concept = instance_double(Glossarist::ManagedConcept, related: related)

      issues = rule.check(make_context(concept, concept_ids: Set.new))
      expect(issues).to be_empty
    end

    it "flags invalid URN format" do
      ref = Glossarist::ConceptRef.new(source: "urn:not a valid urn!!!")
      related = [Glossarist::RelatedConcept.new(content: "test", type: "broader", ref: ref)]
      concept = instance_double(Glossarist::ManagedConcept, related: related)

      issues = rule.check(make_context(concept, concept_ids: Set.new))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("invalid URN")
    end
  end
end
