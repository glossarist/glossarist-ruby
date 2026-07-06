# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::BibliographyYamlRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-020-YAML")
    expect(rule.category).to eq(:structure)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:collection)
  end

  it "is not applicable on a non-GCR context" do
    ds = make_dataset_context(tmpdir)
    expect(rule).not_to be_applicable(ds)
  end

  it "returns no issues when bibliography.yaml parses cleanly" do
    zip = make_gcr_zip(tmpdir, files: {
                         "bibliography.yaml" => <<~YAML,
                           ---
                           bibliography:
                           - id: ISO_9000
                             reference: ISO 9000
                         YAML
                       })
    gcr = make_gcr_context(zip)
    expect(rule.check(gcr)).to be_empty
  end

  it "returns no issues when bibliography.yaml is absent" do
    zip = make_gcr_zip(tmpdir, files: { "metadata.yaml" => "---\n" })
    gcr = make_gcr_context(zip)
    expect(rule.check(gcr)).to be_empty
  end

  it "flags malformed YAML in bibliography.yaml" do
    zip = make_gcr_zip(tmpdir, files: {
                         "bibliography.yaml" => "this: is: not: valid: yaml: [unclosed",
                       })
    gcr = make_gcr_context(zip)
    issues = rule.check(gcr)
    expect(issues.length).to eq(1)
    expect(issues.first.code).to eq("GLS-020-YAML")
    expect(issues.first.message).to include("invalid YAML")
  end
end
