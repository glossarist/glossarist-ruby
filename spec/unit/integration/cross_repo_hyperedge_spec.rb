# frozen_string_literal: true

# Cross-repo integration test for PartitiveHyperedge.
#
# The concept-model repo ships canonical example YAML files at
# `schemas/v3/examples/{20,21,22,23}-partitive-hyperedge-*.yaml`.
# Each downstream repo (glossarist-ruby, glossarist-js,
# concept-browser) exercises the same fixture through its own
# parser/serializer/RDF-emission stack. This file is the Ruby side
# of that contract.
#
# When adding a new hyperedge example to concept-model, add a
# corresponding entry to HYPEREDGE_FIXTURES below so every repo's
# integration spec picks it up.

require "spec_helper"

RSpec.describe "Cross-repo hyperedge integration" do
  CONCEPT_MODEL_ROOT =
    File.expand_path("../../../../concept-model", __dir__)

  HYPEREDGE_FIXTURES = {
    "20-partitive-hyperedge-closed.yaml" => {
      comprehensive_id: "112-02-09",
      parts_count: 2,
      enumeration: "closed",
      markers: ["double"],
    },
    "21-partitive-hyperedge-open.yaml" => {
      comprehensive_id: String, # not asserted; just structure
      parts_count: Integer,
      enumeration: "open",
    },
    "22-partitive-hyperedge-marked.yaml" => {
      comprehensive_id: String,
      parts_count: Integer,
      enumeration: "open",
      markers_includes: %w[double dashed],
    },
    "23-partitive-hyperedge-plain.yaml" => {
      comprehensive_id: "113-01-01",
      parts_count: 2,
      enumeration: "closed", # implicit, schema-default fills in
      markers: [],
    },
  }.freeze

  HYPEREDGE_FIXTURES.each do |filename, expectations|
    it "#{filename} round-trips through V3::ManagedConcept" do
      path = File.join(CONCEPT_MODEL_ROOT, "schemas", "v3", "examples",
                       filename)
      skip "#{filename} not found in concept-model" unless File.exist?(path)

      yaml = File.read(path)
      mc = Glossarist::V3::ManagedConcept.from_yaml(yaml)
      he_list = mc.partitive_hyperedges
      expect(he_list).not_to be_empty

      he = he_list.first
      expect(he.comprehensive.id).to eq(expectations[:comprehensive_id]) unless expectations[:comprehensive_id] == String
      expect(he.parts.length).to eq(expectations[:parts_count]) unless expectations[:parts_count] == Integer
      expect(he.enumeration).to eq(expectations[:enumeration])

      if expectations[:markers]
        expect(he.markers.to_a).to eq(expectations[:markers])
      elsif expectations[:markers_includes]
        expectations[:markers_includes].each do |m|
          expect(he.markers).to include(m)
        end
      end

      # Round-trip back to YAML and re-parse — should be stable.
      re_yaml = mc.to_yaml
      re_mc = Glossarist::V3::ManagedConcept.from_yaml(re_yaml)
      expect(re_mc.partitive_hyperedges.first.comprehensive.id)
        .to eq(he.comprehensive.id)
    end
  end
end
