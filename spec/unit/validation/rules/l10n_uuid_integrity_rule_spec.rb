# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::L10nUuidIntegrityRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-018")
    expect(rule.category).to eq(:integrity)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  it "is not applicable when no localization files have been indexed" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "returns no issues when every referenced UUID has a file" do
    lc_dir = File.join(tmpdir, "concepts", "localized_concept")
    FileUtils.mkdir_p(lc_dir)
    File.write(File.join(lc_dir, "lc-1.yaml"), "---\ndata: {}\n", encoding: "utf-8")

    ds = make_dataset_context(tmpdir)
    mc = make_managed_concept(id: "x")
    mc.data.localized_concepts = { "eng" => "lc-1" }
    cc = make_concept_context(mc, collection_context: ds)
    expect(rule.check(cc)).to be_empty
  end

  it "flags a referenced UUID with no matching file" do
    lc_dir = File.join(tmpdir, "concepts", "localized_concept")
    FileUtils.mkdir_p(lc_dir)
    File.write(File.join(lc_dir, "lc-1.yaml"), "---\ndata: {}\n", encoding: "utf-8")

    ds = make_dataset_context(tmpdir)
    mc = make_managed_concept(id: "x")
    mc.data.localized_concepts = { "eng" => "lc-1", "fra" => "lc-missing" }
    cc = make_concept_context(mc, collection_context: ds, file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("fra")
    expect(issues.first.message).to include("lc-missing")
  end
end
