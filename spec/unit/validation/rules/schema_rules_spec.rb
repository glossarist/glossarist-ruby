# frozen_string_literal: true

require "spec_helper"

# Aggregate spec for schema-family rules. Each rule also has a dedicated
# _spec.rb with richer coverage; this file is retained as an additional
# smoke test using real DatasetContext instances (no doubles).

RSpec.describe "Schema rules" do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  def make_context(concept)
    ds = make_dataset_context(tmpdir)
    ds.add_concept(concept)
    make_concept_context(concept, collection_context: ds)
  end

  describe Glossarist::Validation::Rules::ConceptStatusRule do
    subject(:rule) { described_class.new }

    it "flags invalid concept status" do
      mc = make_managed_concept(id: "1", status: "invalid_status",
                                langs: { eng: {} })
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-201")
    end
  end

  describe Glossarist::Validation::Rules::SourceEnumRule do
    subject(:rule) { described_class.new }

    it "flags invalid source type" do
      mc = make_managed_concept(id: "1", langs: {
                                  eng: { sources: [{ "type" => "invalid_type",
                                                     "origin" => { "ref" => { "source" => "test" } } }] },
                                })
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-202")
    end

    it "flags invalid source status" do
      mc = make_managed_concept(id: "1", langs: {
                                  eng: { sources: [{ "type" => "authoritative", "status" => "bad_status" }] },
                                })
      ctx = make_context(mc)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-203")
    end

    it "passes for valid source type and status" do
      mc = make_managed_concept(id: "1", langs: {
                                  eng: { sources: [{ "type" => "authoritative" }] },
                                })
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::RelatedConceptRule do
    subject(:rule) { described_class.new }

    it "flags invalid related concept type" do
      mc = make_managed_concept(id: "1", langs: { eng: {} })
      mc.related = [Glossarist::RelatedConcept.new(type: "invalid",
                                                   content: { "eng" => "x" })]
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-200")
    end

    it "passes for valid related concept type" do
      mc = make_managed_concept(id: "1", langs: { eng: {} })
      mc.related = [Glossarist::RelatedConcept.new(type: "supersedes",
                                                   content: { "eng" => "x" })]
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end
end
