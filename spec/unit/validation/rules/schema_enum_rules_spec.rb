# frozen_string_literal: true

require "spec_helper"

# Aggregate spec for the schema-enum validation rules. Each rule also has
# a dedicated _spec.rb with richer coverage (see spec/unit/validation/rules/).
# This file is kept for the additional edge cases it covers (e.g. symbol
# designations, date_accepted branching). Uses real model instances via
# ValidationRuleSpecHelper — no doubles.

RSpec.describe Glossarist::Validation::Rules::DesignationStatusRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }
  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "passes for valid normative_status" do
    term = Glossarist::Designation::Expression.new(
      designation: "test", normative_status: "preferred",
    )
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").data.terms = [term]
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "reports invalid normative_status" do
    term = Glossarist::Designation::Expression.new(
      designation: "test", normative_status: "invalid_status",
    )
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").data.terms = [term]
    cc = make_concept_context(mc, collection_context: dataset_context)
    issues = rule.check(cc)
    expect(issues.size).to eq(1)
    expect(issues.first.message).to include("invalid normative_status")
  end

  it "skips nil normative_status" do
    term = Glossarist::Designation::Expression.new(designation: "test")
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").data.terms = [term]
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end
end

RSpec.describe Glossarist::Validation::Rules::DesignationTypeRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }
  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "reports unknown designation type from model" do
    term = Glossarist::Designation::Base.new(type: "unknown_type",
                                             designation: "test")
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").data.terms = [term]
    cc = make_concept_context(mc, collection_context: dataset_context)
    issues = rule.check(cc)
    expect(issues.size).to eq(1)
    expect(issues.first.message).to include("unknown designation type")
  end

  it "passes for symbol designation" do
    term = Glossarist::Designation::Symbol.new(designation: "α")
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").data.terms = [term]
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end
end

RSpec.describe Glossarist::Validation::Rules::DateValidityRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }
  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "checks date_accepted" do
    mc = make_managed_concept(id: "x")
    mc.date_accepted = Glossarist::V3::ConceptDate.new(
      date: "not-a-date", type: "accepted",
    )
    cc = make_concept_context(mc, collection_context: dataset_context)
    issues = rule.check(cc)
    expect(issues.size).to eq(1)
  end
end
