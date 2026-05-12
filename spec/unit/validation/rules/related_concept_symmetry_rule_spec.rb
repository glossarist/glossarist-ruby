# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::RelatedConceptSymmetryRule do
  subject(:rule) { described_class.new }

  let(:code) { "GLS-112" }

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
    expect(rule.code).to eq("GLS-112")
    expect(rule.category).to eq(:references)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:collection)
  end

  it "is applicable when concepts have related" do
    concepts = [make_concept("1", [make_related("supersedes", "2")])]
    expect(rule.applicable?(make_context(concepts))).to be true
  end

  it "is not applicable when no concepts have related" do
    concepts = [make_concept("1")]
    expect(rule.applicable?(make_context(concepts))).to be false
  end

  it "warns when supersedes has no superseded_by back-link" do
    concepts = [
      make_concept("1", [make_related("supersedes", "2")]),
      make_concept("2"),
    ]
    issues = rule.check(make_context(concepts))
    expect(issues.size).to eq(1)
    expect(issues.first.message).to include("supersedes 2")
    expect(issues.first.message).to include("no superseded_by back-link")
  end

  it "warns when narrower has no broader back-link" do
    concepts = [
      make_concept("1", [make_related("narrower", "2")]),
      make_concept("2"),
    ]
    issues = rule.check(make_context(concepts))
    expect(issues.size).to eq(1)
    expect(issues.first.message).to include("no broader back-link")
  end

  it "passes when supersedes/superseded_by are symmetric" do
    concepts = [
      make_concept("1", [make_related("supersedes", "2")]),
      make_concept("2", [make_related("superseded_by", "1")]),
    ]
    issues = rule.check(make_context(concepts))
    expect(issues).to be_empty
  end

  it "passes when narrower/broader are symmetric" do
    concepts = [
      make_concept("1", [make_related("narrower", "2")]),
      make_concept("2", [make_related("broader", "1")]),
    ]
    issues = rule.check(make_context(concepts))
    expect(issues).to be_empty
  end

  it "skips non-directional relation types" do
    concepts = [
      make_concept("1", [make_related("compare", "2")]),
      make_concept("2"),
    ]
    issues = rule.check(make_context(concepts))
    expect(issues).to be_empty
  end
end
