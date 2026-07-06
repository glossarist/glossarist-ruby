# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::LanguageCoverageRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-013")
    expect(rule.category).to eq(:localization)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:concept)
  end

  it "is not applicable when no languages are declared" do
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  context "when register.yaml declares eng + fra" do
    before do
      File.write(File.join(tmpdir, "register.yaml"), <<~YAML, encoding: "utf-8")
        ---
        shortname: test
        languages:
        - eng
        - fra
      YAML
      # Rebuild dataset_context so declared_languages reloads the new file.
      @dataset_context = make_dataset_context(tmpdir)
    end

    let(:dataset_context) { @dataset_context }

    it "returns no issues when the concept covers every declared language" do
      mc = make_managed_concept(id: "x", langs: { eng: {}, fra: {} })
      cc = make_concept_context(mc, collection_context: dataset_context)
      expect(rule.check(cc)).to be_empty
    end

    it "flags a concept missing a declared language" do
      mc = make_managed_concept(id: "x", langs: { eng: {} })
      cc = make_concept_context(mc, collection_context: dataset_context,
                                    file_name: "c.yaml")
      issues = rule.check(cc)
      expect(issues.length).to eq(1)
      expect(issues.first.message).to include("fra")
    end
  end
end
