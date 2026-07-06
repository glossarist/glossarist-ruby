# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::OrphanedL10nFilesRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-019")
    expect(rule.category).to eq(:integrity)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:collection)
  end

  it "is not applicable when the localization_index is empty" do
    ds = make_dataset_context(tmpdir)
    expect(rule).not_to be_applicable(ds)
  end

  context "with two l10n files but only one referenced" do
    let(:dataset_context) do
      lc_dir = File.join(tmpdir, "concepts", "localized_concept")
      FileUtils.mkdir_p(lc_dir)
      File.write(File.join(lc_dir, "lc-referenced.yaml"), "---\ndata: {}\n",
                 encoding: "utf-8")
      File.write(File.join(lc_dir, "lc-orphaned.yaml"), "---\ndata: {}\n",
                 encoding: "utf-8")
      ds = make_dataset_context(tmpdir)
      mc = make_managed_concept(id: "x")
      mc.data.localized_concepts = { "eng" => "lc-referenced" }
      ds.add_concept(mc)
      ds
    end

    it "flags the unreferenced l10n file" do
      issues = rule.check(dataset_context)
      expect(issues.length).to eq(1)
      expect(issues.first.message).to include("lc-orphaned.yaml")
    end
  end

  context "when every l10n file is referenced" do
    let(:dataset_context) do
      lc_dir = File.join(tmpdir, "concepts", "localized_concept")
      FileUtils.mkdir_p(lc_dir)
      File.write(File.join(lc_dir, "lc-1.yaml"), "---\ndata: {}\n",
                 encoding: "utf-8")
      ds = make_dataset_context(tmpdir)
      mc = make_managed_concept(id: "x")
      mc.data.localized_concepts = { "eng" => "lc-1" }
      ds.add_concept(mc)
      ds
    end

    it "returns no issues" do
      expect(rule.check(dataset_context)).to be_empty
    end
  end
end
