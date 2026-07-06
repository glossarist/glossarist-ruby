# frozen_string_literal: true

require "spec_helper"

# Aggregate spec for structure-family rules. Each rule also has a dedicated
# _spec.rb with richer coverage; this file is retained as an additional
# smoke test using real DatasetContext instances (no doubles).

RSpec.describe "Structure rules" do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  def make_context(concept)
    ds = make_dataset_context(tmpdir)
    ds.add_concept(concept)
    make_concept_context(concept, collection_context: ds)
  end

  describe Glossarist::Validation::Rules::ConceptIdRule do
    subject(:rule) { described_class.new }

    it "flags concept with no id" do
      mc = Glossarist::ManagedConcept.new
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-001")
    end

    it "passes for concept with valid id" do
      mc = make_managed_concept(id: "100")
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      expect(rule.check(ctx)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::ConceptIdUniquenessRule do
    subject(:rule) { described_class.new }

    it "flags duplicate concept ids" do
      ds = make_dataset_context(tmpdir)
      ds.add_concept(make_managed_concept(id: "1", langs: { eng: {} }))
      ds.add_concept(make_managed_concept(id: "1", langs: { eng: {} }))
      expect(rule).to be_applicable(ds)
      issues = rule.check(ds)
      expect(issues).not_to be_empty
      expect(issues.first.message).to include("duplicate id")
    end
  end

  describe Glossarist::Validation::Rules::LocalizationPresenceRule do
    subject(:rule) { described_class.new }

    it "flags concept with no localizations" do
      mc = make_managed_concept(id: "1")
      ctx = make_context(mc)
      expect(rule.check(ctx)).not_to be_empty
    end

    it "passes for concept with localizations" do
      mc = make_managed_concept(id: "1", langs: { eng: {} })
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::EntryStatusRule do
    subject(:rule) { described_class.new }

    it "flags invalid entry_status" do
      mc = make_managed_concept(id: "1", langs: { eng: { entry_status: "Standard" } })
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.message).to include("invalid entry_status")
    end

    it "passes for valid entry_status" do
      mc = make_managed_concept(id: "1", langs: { eng: { entry_status: "valid" } })
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::TermsPresenceRule do
    subject(:rule) { described_class.new }

    it "flags localization with no terms" do
      mc = make_managed_concept(id: "1", langs: { eng: {} })
      mc.localization("eng").data.terms = []
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.message).to include("must have at least 1 term")
    end

    it "passes for localization with terms" do
      mc = make_managed_concept(id: "1", langs: { eng: {} })
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end
end
