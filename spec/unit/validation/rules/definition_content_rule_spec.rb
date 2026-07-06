# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::DefinitionContentRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-300")
    expect(rule.category).to eq(:quality)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:concept)
  end

  it "returns no issues when every definition has content" do
    mc = make_managed_concept(id: "x", langs: {
                                eng: { definition: [{ "content" => "a definition" }] },
                              })
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "is not applicable when the concept has no localizations" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "flags a definition with nil content" do
    mc = make_managed_concept(id: "x", langs: {
                                eng: { definition: [{ "content" => nil }] },
                              })
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("definition 1")
    expect(issues.first.message).to include("empty")
    expect(issues.first.location).to include("eng")
  end

  it "flags a definition with whitespace-only content" do
    mc = make_managed_concept(id: "x", langs: {
                                eng: { definition: [{ "content" => "   " }] },
                              })
    cc = make_concept_context(mc, collection_context: dataset_context)
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
  end
end
