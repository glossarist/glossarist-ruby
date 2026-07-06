# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::PreferredTermRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-301")
    expect(rule.category).to eq(:quality)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:concept)
  end

  it "returns no issues when a preferred term exists" do
    mc = make_managed_concept(id: "x", langs: {
                                eng: { terms: [{ "type" => "expression", "designation" => "alpha",
                                                 "normative_status" => "preferred" }] },
                              })
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "is not applicable when the concept has no localizations" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "skips localizations with zero terms" do
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").data.terms = []
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "flags a localization with terms but none preferred" do
    mc = make_managed_concept(id: "x", langs: {
                                eng: { terms: [{ "type" => "expression", "designation" => "alpha",
                                                 "normative_status" => "admitted" }] },
                              })
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("none are preferred")
  end
end
