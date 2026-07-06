# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::CitationCompletenessRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-304")
    expect(rule.category).to eq(:quality)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:concept)
  end

  it "returns no issues when every source has a ref with source or id" do
    src = Glossarist::ConceptSource.new(
      type: "authoritative",
      origin: Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(source: "ISO", id: "1")),
    )
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").data.sources = [src]
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "is not applicable when the concept has no localizations" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "flags a source whose origin.ref is nil" do
    src = Glossarist::ConceptSource.new(
      type: "authoritative",
      origin: Glossarist::Citation.new(ref: nil),
    )
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").data.sources = [src]
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("source 1")
    expect(issues.first.message).to include("empty origin")
  end

  it "flags a source whose origin.ref has neither source nor id" do
    src = Glossarist::ConceptSource.new(
      type: "authoritative",
      origin: Glossarist::Citation.new(
        ref: Glossarist::Citation::Ref.new(source: nil, id: nil),
      ),
    )
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").data.sources = [src]
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc).length).to eq(1)
  end
end
