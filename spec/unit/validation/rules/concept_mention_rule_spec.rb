# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::ConceptMentionRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-100")
    expect(rule.category).to eq(:references)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:concept)
  end

  it "returns no issues when a definition has no inline mentions" do
    mc = make_managed_concept(id: "x", langs: {
                                eng: { definition: [{ "content" => "a plain definition" }] },
                              })
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "is not applicable when the concept has no localizations" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "flags a {{123}} numeric mention whose id is not in concept_ids" do
    mc = make_managed_concept(id: "x", langs: {
                                eng: { definition: [{ "content" => "See {{999}} for context." }] },
                              })
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("999")
    expect(issues.first.suggestion).to include("dataset")
  end

  it "returns no issues when the mentioned id IS in concept_ids" do
    # concept_ids is memoized on DatasetContext — seed both concepts first.
    mentioned = make_managed_concept(id: "123")
    referrer = make_managed_concept(id: "x", langs: {
                                      eng: { definition: [{ "content" => "See {{123}} for context." }] },
                                    })
    dataset_context.add_concept(mentioned)
    dataset_context.add_concept(referrer)
    cc = make_concept_context(referrer, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end
end
