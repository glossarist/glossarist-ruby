# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::DateTypeRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }
  let(:valid_types) { Glossarist::GlossaryDefinition::CONCEPT_DATE_TYPES }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-205")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:concept)
  end

  it "returns no issues when every date has a valid type" do
    valid_types.first(2).each_with_index do |type, idx|
      d = Glossarist::ConceptDate.new(date: Date.new(2020, 1, 1 + idx), type: type)
      mc = make_managed_concept(id: "x", dates: [d])
      cc = make_concept_context(mc, collection_context: dataset_context)
      expect(rule.check(cc)).to be_empty
    end
  end

  it "is not applicable when the concept has no dates" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "flags an invalid date type with the offending index" do
    d = Glossarist::ConceptDate.new(date: Date.new(2020, 1, 1), type: "unknown")
    mc = make_managed_concept(id: "x", dates: [d])
    cc = make_concept_context(mc, collection_context: dataset_context)
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("date 1")
    expect(issues.first.message).to include("unknown")
    expect(issues.first.suggestion).to include(valid_types.first)
  end

  it "skips dates without a type" do
    d = Glossarist::ConceptDate.new(date: Date.new(2020, 1, 1), type: nil)
    mc = make_managed_concept(id: "x", dates: [d])
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end
end
