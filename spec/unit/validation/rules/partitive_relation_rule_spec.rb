# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::PartitiveRelationRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  def make_member(id, presence: "required", count: "exactly_one", is_delimiting: false)
    Glossarist::V3::PartitiveMember.new(
      ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: id),
      presence: presence,
      count: count,
      is_delimiting: is_delimiting,
    )
  end

  def make_relation(comprehensive_id:, member_ids:, completeness: "complete",
                    criterion: nil, type: :partitive)
    comp = Glossarist::V3::ConceptRef.new(source: "VIM", id: comprehensive_id)
    members = member_ids.map { |mid| make_member(mid) }
    kwargs = {
      comprehensive: comp,
      members: members,
      completeness: completeness,
    }
    kwargs[:criterion] = criterion if criterion
    if type == :generic
      Glossarist::V3::GenericRelation.new(**kwargs)
    else
      Glossarist::V3::PartitiveRelation.new(**kwargs)
    end
  end

  def make_v3_concept(id: "x", status: nil)
    kwargs = { data: Glossarist::V3::ManagedConceptData.new(id: id) }
    kwargs[:status] = status if status
    Glossarist::V3::ManagedConcept.new(**kwargs)
  end

  def make_context(concept, relations: [], file_name: "c.yaml")
    make_concept_context(concept, collection_context: dataset_context,
                                  relations: relations, file_name: file_name)
  end

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-221")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  it "is not applicable when the concept has no relations and is not external" do
    mc = make_v3_concept
    cc = make_context(mc)
    expect(rule).not_to be_applicable(cc)
  end

  it "returns no issues for a fully-specified relation with criterion" do
    mc = make_v3_concept
    rel = make_relation(
      comprehensive_id: "1.1",
      member_ids: %w[1.2 1.3],
      criterion: { "eng" => "physical structure" },
    ).validate!
    cc = make_context(mc, relations: [rel])
    expect(rule.check(cc)).to be_empty
  end

  it "warns when a relation has no criterion" do
    mc = make_v3_concept
    rel = make_relation(comprehensive_id: "1.1", member_ids: %w[1.2 1.3]).validate!
    cc = make_context(mc, relations: [rel])
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.severity).to eq("warning")
    expect(issues.first.suggestion).to include("criterion")
  end

  it "errors when a relation has fewer than 2 members" do
    mc = make_v3_concept
    # Build relation without validate! (which would reject the single
    # member). The validator checks the same invariant at the rule
    # semantic level — duplicates the model check on purpose so the
    # rule is meaningful even when validate! is skipped.
    rel = Glossarist::V3::PartitiveRelation.new(
      comprehensive: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.1"),
      members: [
        make_member("1.2"),
      ],
      criterion: { "eng" => "c" },
    )
    cc = make_context(mc, relations: [rel])
    issues = rule.check(cc)
    expect(issues.any? { |i| i.message.include?("fewer than 2 members") }).to be true
  end

  it "errors on duplicate (comprehensive + criterion)" do
    mc = make_v3_concept
    crit = { "eng" => "physical structure" }
    rels = [
      make_relation(comprehensive_id: "1.1", member_ids: %w[1.2 1.3], criterion: crit).validate!,
      make_relation(comprehensive_id: "1.1", member_ids: %w[1.4 1.5], criterion: crit).validate!,
    ]
    cc = make_context(mc, relations: rels)
    issues = rule.check(cc)
    expect(issues.any? { |i| i.message.include?("duplicate") }).to be true
  end

  it "warns when a member has non-default presence" do
    mc = make_v3_concept
    rel = Glossarist::V3::PartitiveRelation.new(
      comprehensive: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.1"),
      members: [
        make_member("1.2", presence: "optional"),
        make_member("1.3"),
      ],
      criterion: { "eng" => "c" },
    ).validate!
    cc = make_context(mc, relations: [rel])
    issues = rule.check(cc)
    expect(issues.any? { |i| i.message.include?("non-default") }).to be true
  end

  it "validates GenericRelation indistinguishably from PartitiveRelation" do
    mc = make_v3_concept
    rel = make_relation(
      comprehensive_id: "5.1",
      member_ids: %w[5.13 3.2],
      criterion: { "eng" => "by realization medium" },
      type: :generic,
    ).validate!
    cc = make_context(mc, relations: [rel])
    expect(rule.check(cc)).to be_empty
  end

  it "uses context.relations (not mc.partitive_relations)" do
    mc = make_v3_concept
    expect(mc.respond_to?(:partitive_relations)).to be(false)
    cc = make_context(mc, relations: [])
    expect(rule).not_to be_applicable(cc)
  end
end
