# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::ConceptCountRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-011")
    expect(rule.category).to eq(:integrity)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:collection)
  end

  it "is not applicable when metadata has no concept_count" do
    zip = make_gcr_zip(tmpdir, files: { "metadata.yaml" => "---\nshortname: x\n" })
    gcr = make_gcr_context(zip)
    expect(rule).not_to be_applicable(gcr)
  end

  it "returns no issues when concept_count matches the actual count" do
    zip = make_gcr_zip(tmpdir, files: {
                         "metadata.yaml" => <<~YAML,
                           ---
                           shortname: x
                           concept_count: 2
                         YAML
                       })
    gcr = make_gcr_context(zip)
    gcr.add_concept(make_managed_concept(id: "1"))
    gcr.add_concept(make_managed_concept(id: "2"))
    expect(rule.check(gcr)).to be_empty
  end

  it "flags a mismatch between declared and actual concept_count" do
    zip = make_gcr_zip(tmpdir, files: {
                         "metadata.yaml" => <<~YAML,
                           ---
                           shortname: x
                           concept_count: 5
                         YAML
                       })
    gcr = make_gcr_context(zip)
    gcr.add_concept(make_managed_concept(id: "1"))
    issues = rule.check(gcr)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("5")
    expect(issues.first.message).to include("1 concept")
  end
end
