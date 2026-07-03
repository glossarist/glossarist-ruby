# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::RelatedConceptCycleRule do
  subject(:rule) { described_class.new }

  def make_concept(id, related = [])
    mc = Glossarist::ManagedConcept.new(data: { "id" => id })
    mc.related = related
    mc
  end

  def make_related(type, ref_id, source: nil)
    rc = Glossarist::RelatedConcept.new(type: type, content: ref_id)
    rc.ref = Glossarist::ConceptRef.new(source: source, id: ref_id)
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

  describe "cross-edition references (regression)" do
    # A supersedes edge across editions points at a concept in another
    # dataset (qualified by source URN). The target concept may share
    # the clause identifier with the source (e.g. both have id 3.1.1.1).
    # The cycle rule must NOT treat this as a self-loop.
    def make_related_cross_edition(type, ref_id, source_urn:)
      make_related(type, ref_id, source: source_urn)
    end

    it "does not flag a supersedes edge to a same-clause predecessor" do
      concepts = [
        make_concept("3.1.1.1", [
                       make_related_cross_edition("supersedes", "3.1.1.1",
                                                  source_urn: "urn:iso:std:iso:ts:14812:2022"),
                     ]),
      ]
      issues = rule.check(make_context(concepts))
      expect(issues).to be_empty
    end

    it "still detects a genuine intra-edition cycle when cross-edition edges also exist" do
      concepts = [
        make_concept("1", [
                       make_related("supersedes", "2"),
                       make_related_cross_edition("supersedes", "1",
                                                  source_urn: "urn:other:edition"),
                     ]),
        make_concept("2", [make_related("supersedes", "1")]),
      ]
      issues = rule.check(make_context(concepts))
      expect(issues).not_to be_empty
      expect(issues.first.message).to include("Circular relation chain")
    end
  end
end
