# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::RelatedConceptRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }
  let(:valid_types) { Glossarist::GlossaryDefinition::RELATED_CONCEPT_TYPES }

  def make_related(type:, ref_id: "1.1")
    rc = Glossarist::RelatedConcept.new(type: type, content: ref_id)
    rc.ref = Glossarist::ConceptRef.new(id: ref_id)
    rc
  end

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-200")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  it "is not applicable when the concept has no related entries" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "returns no issues for every valid relationship type" do
    valid_types.first(3).each do |type|
      mc = make_managed_concept(id: "x")
      mc.related = [make_related(type: type)]
      cc = make_concept_context(mc, collection_context: dataset_context)
      expect(rule.check(cc)).to be_empty, "expected no issues for #{type}"
    end
  end

  it "flags a related concept with an invalid type" do
    mc = make_managed_concept(id: "x")
    mc.related = [make_related(type: "not_a_relationship")]
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("not_a_relationship")
    expect(issues.first.suggestion).to include(valid_types.first)
  end
end
