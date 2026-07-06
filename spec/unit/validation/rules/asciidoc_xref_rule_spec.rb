# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::AsciidocXrefRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-102")
    expect(rule.category).to eq(:references)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:concept)
  end

  it "returns no issues when a definition has no AsciiDoc xrefs" do
    mc = make_managed_concept(id: "x", langs: {
                                eng: { definition: [{ "content" => "a plain definition with no xrefs" }] },
                              })
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "is not applicable when the concept has no localizations" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "flags an AsciiDoc xref that does not resolve against bibliography_index" do
    mc = make_managed_concept(id: "x", langs: {
                                eng: { definition: [{ "content" => "See <<ISO_9000>> for context." }] },
                              })
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("ISO_9000")
    expect(issues.first.suggestion).to include("bibliography.yaml")
  end
end
