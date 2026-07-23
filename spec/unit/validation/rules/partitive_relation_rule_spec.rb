# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::PartitiveRelationRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  def make_relation(comprehensive_id:, partitive_ids:, completeness: "complete",
                    criterion: nil, plurality: nil)
    comp = Glossarist::V3::ConceptRef.new(source: "VIM", id: comprehensive_id)
    parts = partitive_ids.map do |pid|
      Glossarist::V3::PartitiveMember.new(
        ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: pid),
      )
    end
    kwargs = {
      comprehensive: comp,
      partitives: parts,
      completeness: completeness,
    }
    kwargs[:criterion] = criterion if criterion
    kwargs[:plurality] = plurality if plurality
    Glossarist::V3::PartitiveRelation.new(**kwargs)
  end

  def make_v3_concept(id: "x", status: nil)
    kwargs = { data: Glossarist::V3::ManagedConceptData.new(id: id) }
    kwargs[:status] = status if status
    Glossarist::V3::ManagedConcept.new(**kwargs)
  end

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-221")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  it "is not applicable when the concept has no relations and is not external" do
    mc = make_v3_concept
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "returns no issues for a fully-specified relation with criterion" do
    mc = make_v3_concept
    mc.partitive_relations = [
      make_relation(
        comprehensive_id: "1.1",
        partitive_ids: %w[1.2 1.3],
        criterion: { "eng" => "physical structure" },
      ),
    ]
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "warns when a relation has no criterion" do
    mc = make_v3_concept
    mc.partitive_relations = [
      make_relation(comprehensive_id: "1.1", partitive_ids: %w[1.2 1.3]),
    ]
    cc = make_concept_context(mc, collection_context: dataset_context,
                              file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.severity).to eq("warning")
    expect(issues.first.suggestion).to include("criterion")
  end

  it "errors when a relation has fewer than 2 partitives" do
    mc = make_v3_concept
    mc.partitive_relations = [
      make_relation(
        comprehensive_id: "1.1",
        partitive_ids: %w[1.2],
        criterion: { "eng" => "c" },
      ),
    ]
    cc = make_concept_context(mc, collection_context: dataset_context,
                              file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.any? { |i| i.message.include?("fewer than 2 partitives") })
      .to be true
  end

  it "errors on duplicate (comprehensive + criterion)" do
    mc = make_v3_concept
    crit = { "eng" => "physical structure" }
    mc.partitive_relations = [
      make_relation(comprehensive_id: "1.1", partitive_ids: %w[1.2 1.3], criterion: crit),
      make_relation(comprehensive_id: "1.1", partitive_ids: %w[1.4 1.5], criterion: crit),
    ]
    cc = make_concept_context(mc, collection_context: dataset_context,
                              file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.any? { |i| i.message.include?("duplicate PartitiveRelation") })
      .to be true
  end

  it "errors when plurality.is_uncertain without is_shared" do
    mc = make_v3_concept
    mc.partitive_relations = [
      make_relation(
        comprehensive_id: "1.1",
        partitive_ids: %w[1.2 1.3],
        criterion: { "eng" => "c" },
        plurality: Glossarist::V3::TypeSharedPlurality.new(
          is_shared: false, is_uncertain: true,
        ),
      ),
    ]
    cc = make_concept_context(mc, collection_context: dataset_context,
                              file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.any? { |i| i.message.include?("is_uncertain requires") })
      .to be true
  end
end
