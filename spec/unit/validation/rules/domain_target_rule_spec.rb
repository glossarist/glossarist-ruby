# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::DomainTargetRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  def make_concept_with_domain(domain_ref)
    mc = make_managed_concept(id: "x")
    mc.data.domains = [domain_ref]
    mc
  end

  def make_context(concept, concept_ids: Set.new)
    ds = make_dataset_context(tmpdir)
    # Seed concept_ids via add_concept; the set is memoized.
    concept_ids.each do |id|
      ds.add_concept(make_managed_concept(id: id))
    end
    Glossarist::Validation::Rules::ConceptContext.new(
      concept, file_name: "test.yaml", collection_context: ds
    )
  end

  describe "#code" do
    it { expect(rule.code).to eq("GLS-111") }
  end

  describe "#check" do
    it "passes for local domain ref that exists" do
      domain = Glossarist::ConceptReference.new(concept_id: "section-3-1")
      concept = make_concept_with_domain(domain)
      cc = make_context(concept, concept_ids: Set.new(["section-3-1"]))
      expect(rule.check(cc)).to be_empty
    end

    it "flags local domain ref not in dataset" do
      domain = Glossarist::ConceptReference.new(concept_id: "nonexistent")
      concept = make_concept_with_domain(domain)
      cc = make_context(concept, concept_ids: Set.new(["section-3-1"]))
      issues = rule.check(cc)
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("not in dataset")
    end

    it "passes for URN domain" do
      domain = Glossarist::ConceptReference.new(
        concept_id: "section-3-1",
        source: "urn:iso:std:iso:ts:14812",
      )
      concept = make_concept_with_domain(domain)
      cc = make_context(concept)
      expect(rule.check(cc)).to be_empty
    end

    it "flags invalid URN" do
      domain = Glossarist::ConceptReference.new(urn: "urn:invalid urn!!!")
      concept = make_concept_with_domain(domain)
      cc = make_context(concept)
      issues = rule.check(cc)
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("invalid URN")
    end
  end
end
