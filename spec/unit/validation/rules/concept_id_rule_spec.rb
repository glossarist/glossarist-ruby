# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::ConceptIdRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-001")
    expect(rule.category).to eq(:structure)
    expect(rule.scope).to eq(:concept)
  end

  it "returns no issues when concept has an id" do
    mc = make_managed_concept(id: "1.1")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "returns an error when concept id is nil" do
    mc = make_managed_concept(id: nil)
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "no-id.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("missing concept id")
    expect(issues.first.severity).to eq("error")
  end

  it "is always applicable" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).to be_applicable(cc)
  end
end
