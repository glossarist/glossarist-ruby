# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::RelatedConceptTargetRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  def make_context(concept, concept_ids: Set.new)
    ds = make_dataset_context(tmpdir)
    concept_ids.each { |id| ds.add_concept(make_managed_concept(id: id)) }
    Glossarist::Validation::Rules::ConceptContext.new(
      concept, file_name: "test.yaml", collection_context: ds
    )
  end

  def make_concept_with_related(ref:)
    mc = make_managed_concept(id: "x")
    mc.related = [Glossarist::RelatedConcept.new(content: "test",
                                                 type: "broader", ref: ref)]
    mc
  end

  describe "#code" do
    it { expect(rule.code).to eq("GLS-110") }
  end

  describe "#check" do
    it "passes when related concept target exists in dataset" do
      ref = Glossarist::ConceptRef.new(id: "3.1.3.9")
      concept = make_concept_with_related(ref: ref)
      cc = make_context(concept, concept_ids: Set.new(["3.1.3.9"]))
      expect(rule.check(cc)).to be_empty
    end

    it "flags local ref to non-existent concept" do
      ref = Glossarist::ConceptRef.new(id: "9.9.9.9")
      concept = make_concept_with_related(ref: ref)
      cc = make_context(concept, concept_ids: Set.new(["3.1.3.9"]))
      issues = rule.check(cc)
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("not in the dataset")
    end

    it "passes for external ref with valid URN" do
      ref = Glossarist::ConceptRef.new(source: "urn:iso:std:iso:ts:14812",
                                       id: "section-3-1")
      concept = make_concept_with_related(ref: ref)
      cc = make_context(concept)
      expect(rule.check(cc)).to be_empty
    end

    it "flags invalid URN format" do
      ref = Glossarist::ConceptRef.new(source: "urn:not a valid urn!!!")
      concept = make_concept_with_related(ref: ref)
      cc = make_context(concept)
      issues = rule.check(cc)
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("invalid URN")
    end
  end
end
