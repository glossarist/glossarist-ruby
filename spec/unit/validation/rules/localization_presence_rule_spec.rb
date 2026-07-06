# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::LocalizationPresenceRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-002")
    expect(rule.category).to eq(:structure)
    expect(rule.scope).to eq(:concept)
  end

  it "returns no issues when at least one localization exists" do
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "flags a concept with no localizations" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "lonely.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("no localizations")
    expect(issues.first.severity).to eq("warning")
  end

  it "is always applicable" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).to be_applicable(cc)
  end
end
