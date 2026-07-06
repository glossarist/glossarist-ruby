# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::SourceEnumRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }
  let(:valid_types) { Glossarist::GlossaryDefinition::CONCEPT_SOURCE_TYPES }
  let(:valid_statuses) { Glossarist::GlossaryDefinition::CONCEPT_SOURCE_STATUSES }

  def make_source(type: "authoritative", status: "identical")
    Glossarist::ConceptSource.new(
      type: type,
      status: status,
      origin: Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(source: "ISO")),
    )
  end

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-202")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  it "returns no issues for a source with valid type and status" do
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").data.sources = [make_source]
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "is not applicable when the concept has no localizations" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "flags a source with an invalid type" do
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").data.sources = [make_source(type: "invented")]
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.code).to eq("GLS-202")
    expect(issues.first.message).to include("invalid type")
    expect(issues.first.suggestion).to include(valid_types.first)
  end

  it "flags a source with an invalid status (separate GLS-203 code)" do
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").data.sources = [make_source(status: "wrong")]
    cc = make_concept_context(mc, collection_context: dataset_context)
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.code).to eq("GLS-203")
    expect(issues.first.message).to include("invalid status")
    expect(issues.first.suggestion).to include(valid_statuses.first)
  end
end
