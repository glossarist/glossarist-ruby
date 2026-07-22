# frozen_string: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::PartitiveHyperedgeRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  def make_hyperedge(enumeration: nil, markers: [])
    kwargs = {
      comprehensive: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.1"),
      parts: [
        Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2"),
        Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.3"),
      ],
      markers: markers,
    }
    kwargs[:enumeration] = enumeration if enumeration
    Glossarist::V3::PartitiveHyperedge.new(**kwargs)
  end

  def make_v3_concept(id: "x")
    Glossarist::V3::ManagedConcept.new(
      data: Glossarist::V3::ManagedConceptData.new(id: id),
    )
  end

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-220")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  it "is not applicable when the concept has no hyperedges" do
    mc = make_v3_concept
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "returns no issues for a fully-specified hyperedge" do
    mc = make_v3_concept
    mc.partitive_hyperedges = [make_hyperedge(enumeration: "closed",
                                              markers: ["double"])]
    cc = make_concept_context(mc, collection_context: dataset_context)
    issues = rule.check(cc)
    expect(issues).to be_empty
  end

  it "warns when enumeration is implicit (default applied)" do
    mc = make_v3_concept
    mc.partitive_hyperedges = [make_hyperedge]  # no enumeration kwarg
    cc = make_concept_context(mc, collection_context: dataset_context,
                              file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.severity).to eq("warning")
    expect(issues.first.suggestion).to include("closed")
  end

  it "does not warn when enumeration is explicit even if value is 'closed'" do
    mc = make_v3_concept
    mc.partitive_hyperedges = [make_hyperedge(enumeration: "closed")]
    cc = make_concept_context(mc, collection_context: dataset_context,
                              file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues).to be_empty
  end

  it "flags an invalid marker value" do
    # Build via from_hash so the raw value bypasses the constructor's
    # validate_markers! (lutaml-model's enum-collection setter
    # dedupes but does not validate `values:` on assignment).
    he = Glossarist::V3::PartitiveHyperedge.from_hash(
      "comprehensive" => { "source" => "VIM", "id" => "1.1" },
      "parts" => [{ "source" => "VIM", "id" => "1.2" }],
      "enumeration" => "closed",
      "markers" => ["dotted"],
    )
    mc = make_v3_concept
    mc.partitive_hyperedges = [he]
    cc = make_concept_context(mc, collection_context: dataset_context,
                              file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.any? { |i| i.message.include?("invalid value") }).to be true
  end
end
