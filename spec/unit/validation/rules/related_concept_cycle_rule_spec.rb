# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::RelatedConceptCycleRule do
  subject(:rule) { described_class.new }

  def make_concept(id, related = [])
    mc = Glossarist::ManagedConcept.new(data: { "id" => id })
    mc.related = related
    mc
  end

  def make_related(type, ref_id)
    rc = Glossarist::RelatedConcept.new(type: type, content: ref_id)
    citation = Glossarist::Citation.new
    citation.ref = { "id" => ref_id, "source" => "test" }
    rc.ref = citation
    rc
  end

  def make_context(concepts)
    ctx = instance_double(Glossarist::Validation::Rules::DatasetContext)
    allow(ctx).to receive(:concepts).and_return(concepts)
    ctx
  end

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-113")
    expect(rule.category).to eq(:references)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:collection)
  end

  it "detects a direct cycle (A -> B -> A)" do
    concepts = [
      make_concept("1", [make_related("supersedes", "2")]),
      make_concept("2", [make_related("supersedes", "1")]),
    ]
    issues = rule.check(make_context(concepts))
    expect(issues).not_to be_empty
    expect(issues.first.message).to include("Circular relation chain")
  end

  it "detects a longer cycle (A -> B -> C -> A)" do
    concepts = [
      make_concept("1", [make_related("supersedes", "2")]),
      make_concept("2", [make_related("supersedes", "3")]),
      make_concept("3", [make_related("supersedes", "1")]),
    ]
    issues = rule.check(make_context(concepts))
    expect(issues).not_to be_empty
    expect(issues.first.message).to include("Circular relation chain")
  end

  it "passes when no cycles exist" do
    concepts = [
      make_concept("1", [make_related("supersedes", "2")]),
      make_concept("2", [make_related("supersedes", "3")]),
      make_concept("3"),
    ]
    issues = rule.check(make_context(concepts))
    expect(issues).to be_empty
  end

  it "only considers directional types" do
    concepts = [
      make_concept("1", [make_related("compare", "2")]),
      make_concept("2", [make_related("compare", "1")]),
    ]
    issues = rule.check(make_context(concepts))
    expect(issues).to be_empty
  end

  it "is not applicable when no concepts have related" do
    concepts = [make_concept("1")]
    expect(rule.applicable?(make_context(concepts))).to be false
  end
end
