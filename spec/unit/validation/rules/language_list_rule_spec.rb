# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::LanguageListRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-012")
    expect(rule.category).to eq(:integrity)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:collection)
  end

  it "is not applicable when no languages are declared" do
    ds = make_dataset_context(tmpdir)
    expect(rule).not_to be_applicable(ds)
  end

  context "when register.yaml declares eng + fra but concepts use eng + deu" do
    let(:dataset_context) do
      File.write(File.join(tmpdir, "register.yaml"), <<~YAML, encoding: "utf-8")
        ---
        shortname: test
        languages:
        - eng
        - fra
      YAML
      ds = make_dataset_context(tmpdir)
      ds.add_concept(make_managed_concept(id: "1", langs: { eng: {} }))
      ds.add_concept(make_managed_concept(id: "2", langs: { deu: {} }))
      ds
    end

    it "reports both missing (fra) and extra (deu) languages" do
      issues = rule.check(dataset_context)
      messages = issues.map(&:message).join("\n")
      expect(messages).to include("fra")
      expect(messages).to include("deu")
    end
  end

  context "when declared and actual languages match exactly" do
    let(:dataset_context) do
      File.write(File.join(tmpdir, "register.yaml"), <<~YAML, encoding: "utf-8")
        ---
        shortname: test
        languages:
        - eng
        - fra
      YAML
      ds = make_dataset_context(tmpdir)
      ds.add_concept(make_managed_concept(id: "1", langs: { eng: {}, fra: {} }))
      ds
    end

    it "returns no issues" do
      expect(rule.check(dataset_context)).to be_empty
    end
  end
end
