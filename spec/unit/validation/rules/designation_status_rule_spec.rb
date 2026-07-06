# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::DesignationStatusRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }
  let(:valid_statuses) { Glossarist::GlossaryDefinition::DESIGNATION_BASE_NORMATIVE_STATUSES }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-204")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  it "returns no issues for every valid normative_status" do
    valid_statuses.each do |status|
      mc = make_managed_concept(id: "x", langs: {
                                  eng: { terms: [{ "type" => "expression", "designation" => "t",
                                                   "normative_status" => status }] },
                                })
      cc = make_concept_context(mc, collection_context: dataset_context)
      expect(rule.check(cc)).to be_empty, "expected no issues for #{status}"
    end
  end

  it "skips terms with no normative_status" do
    mc = make_managed_concept(id: "x", langs: {
                                eng: { terms: [{ "type" => "expression", "designation" => "t",
                                                 "normative_status" => nil }] },
                              })
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "flags a term with an invalid normative_status" do
    mc = make_managed_concept(id: "x", langs: {
                                eng: { terms: [{ "type" => "expression", "designation" => "t",
                                                 "normative_status" => "best_ever" }] },
                              })
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("best_ever")
    expect(issues.first.suggestion).to include(valid_statuses.first)
  end
end
