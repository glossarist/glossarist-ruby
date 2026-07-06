# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::ConceptStatusRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }
  let(:valid_statuses) { Glossarist::GlossaryDefinition::CONCEPT_STATUSES }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-201")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  it "returns no issues for a valid status" do
    valid_statuses.first(3).each do |status|
      mc = make_managed_concept(id: "x", status: status)
      cc = make_concept_context(mc, collection_context: dataset_context)
      expect(rule.check(cc)).to be_empty
    end
  end

  it "is not applicable when concept has no status" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "flags an invalid status with a suggestion listing valid values" do
    mc = make_managed_concept(id: "x", status: "not_a_status")
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "bad.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("not_a_status")
    expect(issues.first.suggestion).to include(valid_statuses.first)
    expect(issues.first.severity).to eq("error")
  end
end
