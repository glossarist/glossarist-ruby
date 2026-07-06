# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::DomainRefRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }
  let(:dataset_context) { make_dataset_context(tmpdir) }

  def make_context(concept)
    Glossarist::Validation::Rules::ConceptContext.new(
      concept, file_name: "test.yaml", collection_context: dataset_context
    )
  end

  def make_concept_with_domain(domain_ref)
    mc = make_managed_concept(id: "x")
    mc.data.domains = [domain_ref]
    mc
  end

  describe "#code" do
    it { expect(rule.code).to eq("GLS-309") }
  end

  describe "#check" do
    it "passes for domain with concept_id" do
      domain = Glossarist::ConceptReference.new(concept_id: "section-3-1")
      concept = make_concept_with_domain(domain)
      expect(rule.check(make_context(concept))).to be_empty
    end

    it "passes for domain with urn" do
      domain = Glossarist::ConceptReference.new(urn: "urn:iso:std:iso:ts:14812")
      concept = make_concept_with_domain(domain)
      expect(rule.check(make_context(concept))).to be_empty
    end

    it "flags domain with neither concept_id nor urn" do
      domain = Glossarist::ConceptReference.new(source: "ISO")
      concept = make_concept_with_domain(domain)
      issues = rule.check(make_context(concept))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("neither concept_id nor urn")
    end
  end
end
