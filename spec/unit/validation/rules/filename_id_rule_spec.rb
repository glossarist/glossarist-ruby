# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::FilenameIdRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-015")
    expect(rule.category).to eq(:integrity)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  it "is not applicable on a non-GCR context" do
    ds = make_dataset_context(tmpdir)
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: ds)
    expect(rule).not_to be_applicable(cc)
  end

  it "returns no issues when the filename matches the concept id" do
    zip = make_gcr_zip(tmpdir, files: { "metadata.yaml" => "---\n" })
    gcr = make_gcr_context(zip)
    mc = make_managed_concept(id: "1.1")
    cc = make_concept_context(mc, collection_context: gcr,
                                  file_name: "concepts/1.1.yaml")
    expect(rule.check(cc)).to be_empty
  end

  it "flags a filename that does not match the concept id" do
    zip = make_gcr_zip(tmpdir, files: { "metadata.yaml" => "---\n" })
    gcr = make_gcr_context(zip)
    mc = make_managed_concept(id: "1.1")
    cc = make_concept_context(mc, collection_context: gcr,
                                  file_name: "concepts/something-else.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("something-else")
    expect(issues.first.message).to include("1.1")
  end
end
