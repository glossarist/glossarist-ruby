# frozen_string_literal: true

require "spec_helper"

# Cross-repo integration: verifies that a PartitiveRelation YAML
# fixture authored against the concept-model v3 per-file relation
# format round-trips through glossarist-ruby's V3::RelationLoader
# and V3::PartitiveRelation.
#
# The concept-model examples live at:
#   ../concept-model/schemas/v3/examples/relations/<id>/<slug>.yaml
#
# If the concept-model path is unavailable (e.g. running in an isolated
# build), the spec is skipped.
RSpec.describe "Cross-repo per-file relation integration" do
  let(:concept_model_relations_dir) do
    File.expand_path("../../../../concept-model/schemas/v3/examples/relations", __dir__)
  end

  let(:available) { File.directory?(concept_model_relations_dir) }

  before do
    skip "concept-model repo not present at expected path" unless available
  end

  it "loads every relation file via RelationLoader" do
    relations = Glossarist::V3::RelationLoader.load_all(concept_model_relations_dir)
    expect(relations).not_to be_empty

    relations.each_value do |list|
      list.each do |rel|
        expect(rel).to be_a(Glossarist::V3::AbstractNaryRelation)
        expect(rel.members.length).to be >= 2
      end
    end
  end

  it "loads the VIM measurement-result-composition PartitiveRelation" do
    loader = Glossarist::V3::RelationLoader.new(concept_model_relations_dir)
    relations = loader.load_for_comprehensive("vim-112-02-09")
    expect(relations.length).to eq(1)
    rel = relations.first
    expect(rel).to be_a(Glossarist::V3::PartitiveRelation)
    expect(rel.comprehensive.id).to eq("112-02-09")
    expect(rel.members.map { |m| m.ref.id }).to eq(%w[112-02-10 112-03-26])
    expect(rel.completeness).to eq("complete")
    expect(rel.criterion).to eq("eng" => "measurement result composition")
  end

  it "loads a dual-criterion comprehensive (two distinct decompositions)" do
    loader = Glossarist::V3::RelationLoader.new(concept_model_relations_dir)
    relations = loader.load_for_comprehensive("example-116-01-01")
    expect(relations.length).to eq(2)
    criteria = relations.map { |r| r.criterion["eng"] }.sort
    expect(criteria).to eq(["functional subsystem", "physical structure"])
  end

  it "every loaded PartitiveRelation passes validate!" do
    relations = Glossarist::V3::RelationLoader.load_all(concept_model_relations_dir)
    relations.values.flatten.each do |rel|
      next unless rel.is_a?(Glossarist::V3::PartitiveRelation)

      expect { rel.validate! }.not_to raise_error
    end
  end
end
