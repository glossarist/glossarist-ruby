# frozen_string_literal: true

require "spec_helper"
require "date"

RSpec.describe Glossarist::Validation::Rules::DateValidityRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-307")
    expect(rule.category).to eq(:quality)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:concept)
  end

  it "returns no issues for a parseable ISO 8601 date" do
    d = Glossarist::ConceptDate.new(date: Date.new(2024, 1, 15), type: "accepted")
    mc = make_managed_concept(id: "x", dates: [d])
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "is not applicable when the concept has no dates" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "flags an unparseable date string" do
    # V3::ConceptDate keeps `date` as a free-form string, so unparseable
    # values survive to the validator (base ConceptDate's :date_time type
    # would coerce them to nil before validation runs).
    d = Glossarist::V3::ConceptDate.new(date: "not-a-date", type: "accepted")
    mc = make_managed_concept(id: "x", dates: [d])
    cc = make_concept_context(mc, collection_context: dataset_context)
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("unparseable")
    expect(issues.first.message).to include("not-a-date")
  end

  it "flags a typed date with no value" do
    d = Glossarist::ConceptDate.new(date: nil, type: "accepted")
    mc = make_managed_concept(id: "x", dates: [d])
    cc = make_concept_context(mc, collection_context: dataset_context)
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("no date value")
  end
end
