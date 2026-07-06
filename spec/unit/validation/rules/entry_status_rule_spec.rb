# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::EntryStatusRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-003")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  %w[valid superseded withdrawn draft].each do |status|
    it "returns no issues for entry_status '#{status}'" do
      mc = make_managed_concept(id: "x", langs: { eng: { entry_status: status } })
      cc = make_concept_context(mc, collection_context: dataset_context)
      expect(rule.check(cc)).to be_empty
    end
  end

  it "skips localizations with no entry_status" do
    mc = make_managed_concept(id: "x", langs: { eng: { entry_status: nil } })
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "flags an invalid entry_status with the offending language in the location" do
    mc = make_managed_concept(id: "x", langs: { fra: { entry_status: "bogus" } })
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("bogus")
    expect(issues.first.location).to include("fra")
  end
end
