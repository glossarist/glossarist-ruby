# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::HyperedgeIndex do
  let(:ref) do
    ->(source, id) { Glossarist::V3::ConceptRef.new(source: source, id: id) }
  end

  let(:oiml_5_1_relations) do
    # The canonical OIML V 2-200:2010 multi-hyperedge case: concept
    # 5.1 measurement standard has 6 hyperedges with different criteria.
    criteria = %w[
      by-realization-medium
      by-calibration-role
      by-governance-level
      by-metrological-hierarchy
      by-reference-working
      by-travel
    ].map { |c| { "eng" => c.tr("-", " ") } }

    criteria.map do |crit|
      Glossarist::V3::GenericHyperedge.new(
        comprehensive: ref.call("OIML", "5.1"),
        members: [
          Glossarist::V3::GenericMember.new(ref: ref.call("OIML", "5.13")),
          Glossarist::V3::GenericMember.new(ref: ref.call("OIML", "3.2")),
        ],
        criterion: crit,
      )
    end
  end

  let(:hyperedges) do
    # 5.13 reference material is comprehensive in its own 2 hyperedges
    # AND member of one of 5.1's hyperedges.
    five_point_thirteen = [
      Glossarist::V3::GenericHyperedge.new(
        comprehensive: ref.call("OIML", "5.13"),
        members: [
          Glossarist::V3::GenericMember.new(ref: ref.call("OIML", "5.14")),
          Glossarist::V3::GenericMember.new(ref: ref.call("OIML", "X")),
        ],
        criterion: { "eng" => "by certification" },
      ),
      Glossarist::V3::GenericHyperedge.new(
        comprehensive: ref.call("OIML", "5.13"),
        members: [
          Glossarist::V3::GenericMember.new(ref: ref.call("OIML", "Y")),
          Glossarist::V3::GenericMember.new(ref: ref.call("OIML", "Z")),
        ],
        criterion: { "eng" => "by purpose" },
      ),
    ]
    oiml_5_1_relations + five_point_thirteen
  end

  subject(:index) { described_class.new(hyperedges) }

  describe "#for_comprehensive" do
    it "returns all hyperedges for a comprehensive id" do
      expect(index.for_comprehensive("OIML:5.1").length).to eq(6)
    end

    it "returns hyperedges for a ConceptRef as well as a string" do
      r = Glossarist::V3::ConceptRef.new(source: "OIML", id: "5.13")
      expect(index.for_comprehensive(r).length).to eq(2)
    end

    it "returns empty for an unknown id" do
      expect(index.for_comprehensive("OIML:nope")).to eq([])
    end
  end

  describe "#for_member" do
    it "returns hyperedges where the concept appears as a member" do
      # 5.13 is a member of one of 5.1's hyperedges (6 of them)
      expect(index.for_member("OIML:5.13").length).to eq(6)
    end

    it "returns hyperedges for a ConceptRef as well as a string" do
      r = Glossarist::V3::ConceptRef.new(source: "OIML", id: "5.14")
      expect(index.for_member(r).length).to eq(1)
    end

    it "returns empty for an unknown id" do
      expect(index.for_member("OIML:nope")).to eq([])
    end
  end

  describe "concept that is BOTH comprehensive AND member" do
    it "5.13 appears in both indexes" do
      expect(index.for_comprehensive("OIML:5.13").length).to eq(2)
      expect(index.for_member("OIML:5.13").length).to eq(6)
    end
  end

  describe "#all_concept_ids" do
    it "returns the union of comprehensive and member ids" do
      ids = index.all_concept_ids
      expect(ids).to include("OIML:5.1", "OIML:5.13", "OIML:3.2", "OIML:5.14")
    end
  end

  describe "with empty input" do
    subject(:empty_index) { described_class.new([]) }

    it "returns empty for every query" do
      expect(empty_index.for_comprehensive("X:1")).to eq([])
      expect(empty_index.for_member("X:1")).to eq([])
      expect(empty_index.all_concept_ids).to eq([])
    end
  end

  describe "with mixed-type hyperedges" do
    let(:mixed) do
      [
        Glossarist::V3::PartitiveHyperedge.new(
          comprehensive: ref.call("VIM", "1"),
          members: [
            Glossarist::V3::PartitiveMember.new(ref: ref.call("VIM", "2")),
            Glossarist::V3::PartitiveMember.new(ref: ref.call("VIM", "3")),
          ],
          criterion: { "eng" => "physical" },
        ),
        Glossarist::V3::GenericHyperedge.new(
          comprehensive: ref.call("VIM", "1"),
          members: [
            Glossarist::V3::GenericMember.new(ref: ref.call("VIM", "4")),
            Glossarist::V3::GenericMember.new(ref: ref.call("VIM", "5")),
          ],
          criterion: { "eng" => "functional" },
        ),
      ]
    end

    subject(:mixed_index) { described_class.new(mixed) }

    it "returns both types from for_comprehensive" do
      rels = mixed_index.for_comprehensive("VIM:1")
      types = rels.map(&:class).map(&:name)
      expect(types).to include("Glossarist::V3::PartitiveHyperedge")
      expect(types).to include("Glossarist::V3::GenericHyperedge")
    end
  end
end
