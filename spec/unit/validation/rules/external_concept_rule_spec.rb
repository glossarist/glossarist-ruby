# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::ExternalConceptRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  let(:external_with_resolution) do
    c = Glossarist::V3::ManagedConcept.new(
      data: Glossarist::V3::ManagedConceptData.new(id: "ext-1"),
    )
    c.status = "external"
    c.related = [
      Glossarist::V3::RelatedConcept.new(
        type: "provided_by",
        ref: Glossarist::V3::ConceptRef.new(source: "OIML", id: "5.1"),
      ),
    ]
    c
  end

  let(:external_dangling) do
    c = Glossarist::V3::ManagedConcept.new(
      data: Glossarist::V3::ManagedConceptData.new(id: "ext-2"),
    )
    c.status = "external"
    c
  end

  let(:resolver) do
    table = {
      "OIML:ext-1" => external_with_resolution,
      "OIML:ext-2" => external_dangling,
    }
    ->(ref) { table[Glossarist::ConceptRef.qualified_id(ref)] }
  end

  def make_relation(comprehensive_id:, member_ids:, criterion: "by example")
    Glossarist::V3::GenericHyperedge.new(
      comprehensive: Glossarist::V3::ConceptRef.new(source: "OIML", id: comprehensive_id),
      members: member_ids.map do |mid|
        Glossarist::V3::GenericMember.new(
          ref: Glossarist::V3::ConceptRef.new(source: "OIML", id: mid),
        )
      end,
      criterion: { "eng" => criterion },
    )
  end

  def make_context(relations:, resolver: nil)
    mc = Glossarist::V3::ManagedConcept.new(
      data: Glossarist::V3::ManagedConceptData.new(id: "5.1"),
    )
    Glossarist::Validation::Rules::ConceptContext.new(
      mc,
      file_name: "c.yaml",
      collection_context: dataset_context,
      relations: relations,
      concept_resolver: resolver,
    )
  end

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-222")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:concept)
  end

  it "is not applicable when no concept_resolver is supplied" do
    ctx = make_context(
      relations: [make_relation(comprehensive_id: "ext-1", member_ids: %w[ext-2])],
      resolver: nil,
    )
    expect(rule).not_to be_applicable(ctx)
  end

  it "is not applicable when there are no relations" do
    ctx = make_context(relations: [], resolver: resolver)
    expect(rule).not_to be_applicable(ctx)
  end

  it "warns on dangling external member (no provided_by)" do
    rel = make_relation(comprehensive_id: "5.1", member_ids: %w[ext-1 ext-2])
    ctx = make_context(relations: [rel], resolver: resolver)
    issues = rule.check(ctx)
    # ext-1 has provided_by (info only); ext-2 dangles (warning)
    dangling = issues.select { |i| i.severity == "warning" }
    expect(dangling.length).to eq(1)
    expect(dangling.first.message).to include("ext-2")
    expect(dangling.first.message).to include("dangles")
  end

  it "emits info (not warning) when external comprehensive has provided_by" do
    # ext-1 has provided_by — using it as comprehensive produces an info
    # message confirming resolution exists.
    rel = make_relation(comprehensive_id: "ext-1", member_ids: %w[5.1 5.2])
    # Add a normal second concept so the resolver doesn't have to find them
    normal = Glossarist::V3::ManagedConcept.new(
      data: Glossarist::V3::ManagedConceptData.new(id: "5.1"),
    )
    normal2 = Glossarist::V3::ManagedConcept.new(
      data: Glossarist::V3::ManagedConceptData.new(id: "5.2"),
    )
    resolver_with_normals = ->(ref) {
      {
        "OIML:ext-1" => external_with_resolution,
        "OIML:5.1" => normal,
        "OIML:5.2" => normal2,
      }[Glossarist::ConceptRef.qualified_id(ref)]
    }
    ctx = make_context(relations: [rel], resolver: resolver_with_normals)
    issues = rule.check(ctx)
    infos = issues.select { |i| i.severity == "info" }
    expect(infos.length).to eq(1)
    expect(infos.first.message).to include("ext-1")
    expect(infos.first.message).to include("provided_by")
  end

  it "returns no issues when every external has provided_by" do
    external_dangling.related = [
      Glossarist::V3::RelatedConcept.new(
        type: "provided_by",
        ref: Glossarist::V3::ConceptRef.new(source: "OIML", id: "5.1"),
      ),
    ]
    rel = make_relation(comprehensive_id: "5.1", member_ids: %w[ext-1 ext-2])
    ctx = make_context(relations: [rel], resolver: resolver)
    warnings = rule.check(ctx).select { |i| i.severity == "warning" }
    expect(warnings).to be_empty
  end

  it "flags external comprehensive" do
    rel = make_relation(comprehensive_id: "ext-2", member_ids: %w[ext-1])
    ctx = make_context(relations: [rel], resolver: resolver)
    issues = rule.check(ctx)
    expect(issues.any? { |i| i.message.include?("comprehensive") && i.message.include?("ext-2") })
      .to be(true)
  end
end
