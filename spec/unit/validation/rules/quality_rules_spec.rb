# frozen_string_literal: true

require "spec_helper"

# Aggregate spec for quality-family rules. Each rule also has a dedicated
# _spec.rb with richer coverage; this file is retained as an additional
# smoke test using real DatasetContext instances (no doubles).

RSpec.describe "Quality rules" do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  def make_context(concept)
    ds = make_dataset_context(tmpdir)
    ds.add_concept(concept)
    make_concept_context(concept, collection_context: ds)
  end

  describe Glossarist::Validation::Rules::PreferredTermRule do
    subject(:rule) { described_class.new }

    it "warns when no term is preferred" do
      mc = make_managed_concept(id: "1", langs: {
                                  eng: { terms: [{ "type" => "expression", "designation" => "test" }] },
                                })
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-301")
    end

    it "passes when a term is preferred" do
      mc = make_managed_concept(id: "1", langs: { eng: {} })
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::DuplicateTermRule do
    subject(:rule) { described_class.new }

    it "warns on duplicate preferred terms across concepts" do
      ds = make_dataset_context(tmpdir)
      ds.add_concept(make_managed_concept(id: "1", langs: { eng: {} }))
      ds.add_concept(make_managed_concept(id: "2", langs: { eng: {} }))
      expect(rule).to be_applicable(ds)
      issues = rule.check(ds)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-302")
    end

    it "passes when terms are unique across concepts" do
      ds = make_dataset_context(tmpdir)
      ds.add_concept(make_managed_concept(id: "1", langs: { eng: {} }))
      ds.add_concept(make_managed_concept(id: "2", langs: {
                                            eng: { terms: [{ "type" => "expression", "designation" => "different",
                                                             "normative_status" => "preferred" }] },
                                          }))
      expect(rule.check(ds)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::DefinitionContentRule do
    subject(:rule) { described_class.new }

    it "warns on empty definition content" do
      mc = make_managed_concept(id: "1", langs: {
                                  eng: { definition: [{ "content" => "" }] },
                                })
      ctx = make_context(mc)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-300")
    end

    it "passes for non-empty definition" do
      mc = make_managed_concept(id: "1", langs: { eng: {} })
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::AuthoritativeSourceRule do
    subject(:rule) { described_class.new }

    it "warns when no authoritative source is defined" do
      mc = make_managed_concept(id: "1", langs: {
                                  eng: { sources: [{ "type" => "lineage",
                                                     "origin" => { "ref" => { "source" => "test" } } }] },
                                })
      ctx = make_context(mc)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-306")
    end

    it "passes when authoritative source is present" do
      mc = make_managed_concept(id: "1", langs: {
                                  eng: { sources: [{ "type" => "authoritative" }] },
                                })
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end
end
