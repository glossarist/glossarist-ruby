# frozen_string_literal: true

require "spec_helper"

# Cross-repo integration: verifies that a PartitiveRelation YAML
# fixture authored against the concept-model v3 schema round-trips
# through glossarist-ruby's V3::ManagedConcept.
#
# Fixtures are inline (not loaded from ../concept-model) because the
# concept-model maintainer's TODO.partitive-relation-v2 plan item 09
# ("Rewrite examples 20-23") hasn't landed yet. When it does, these
# inline fixtures can be replaced with paths into the concept-model
# repo's examples directory.
RSpec.describe "Cross-repo partitive relation integration" do
  YAML_FIXTURES = {
    "closed-complete" => <<~YAML,
      ---
      identifier: '112-02-09'
      partitive_relations:
      - comprehensive:
          source: VIM
          id: '112-02-09'
        partitives:
        - ref:
            source: VIM
            id: '112-02-10'
        - ref:
            source: VIM
            id: '112-03-26'
        completeness: complete
        criterion:
          eng: measurement result composition
    YAML
    "partial" => <<~YAML,
      ---
      identifier: '112-01-03'
      partitive_relations:
      - comprehensive:
          source: VIM
          id: '112-01-03'
        partitives:
        - ref:
            source: VIM
            id: '112-01-04'
        - ref:
            source: VIM
            id: '112-01-05'
        - ref:
            source: VIM
            id: '112-01-22'
        completeness: partial
        criterion:
          eng: quantity system decomposition
    YAML
    "with-member-dimensions" => <<~YAML,
      ---
      identifier: '112-02-09'
      partitive_relations:
      - comprehensive:
          source: VIM
          id: '112-02-09'
        partitives:
        - ref:
            source: VIM
            id: '112-02-10'
          presence: required
          count: multiple
          is_delimiting: true
        - ref:
            source: VIM
            id: '112-03-26'
          presence: optional
          count: exactly_one
        completeness: complete
        criterion:
          eng: measurement result composition
    YAML
    "plain" => <<~YAML,
      ---
      identifier: '113-01-01'
      partitive_relations:
      - comprehensive:
          source: EXAMPLE
          id: '113-01-01'
        partitives:
        - ref:
            source: EXAMPLE
            id: '113-01-02'
        - ref:
            source: EXAMPLE
            id: '113-01-03'
        # completeness omitted → defaults to complete via schema default
        criterion:
          eng: simple decomposition
    YAML
  }.freeze

  YAML_FIXTURES.each do |label, yaml|
    it "#{label} round-trips through V3::ManagedConcept" do
      mc = Glossarist::V3::ManagedConcept.from_yaml(yaml)
      rel_list = mc.partitive_relations
      expect(rel_list.length).to eq(1)
      rel = rel_list.first
      expect(rel.partitives.length).to be >= 2
      expect(rel).to be_coordinate
      rel.validate!
    end
  end

  it "with-member-dimensions preserves presence/count/is_delimiting" do
    mc = Glossarist::V3::ManagedConcept.from_yaml(YAML_FIXTURES["with-member-dimensions"])
    members = mc.partitive_relations.first.partitives
    expect(members.first.presence).to eq("required")
    expect(members.first.count).to eq("multiple")
    expect(members.first.is_delimiting).to be(true)
    expect(members.last.presence).to eq("optional")
    expect(members.last.count).to eq("exactly_one")
    expect(members.last.is_delimiting).to be(false)
  end
end
