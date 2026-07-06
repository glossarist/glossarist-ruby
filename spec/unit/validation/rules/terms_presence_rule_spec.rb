# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::TermsPresenceRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-005")
    expect(rule.category).to eq(:structure)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  it "returns no issues when every localization has at least one term" do
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "is not applicable when the concept has no localizations" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "flags a localization with no terms" do
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").data.terms = []
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("at least 1 term")
    expect(issues.first.location).to include("eng")
  end
end
