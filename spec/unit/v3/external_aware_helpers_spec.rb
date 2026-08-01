# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::AbstractHyperedge, "external-aware helpers" do
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

  let(:normal_concept) do
    Glossarist::V3::ManagedConcept.new(
      data: Glossarist::V3::ManagedConceptData.new(id: "5.1"),
    )
  end

  let(:resolver) do
    table = {
      "OIML:ext-1" => external_with_resolution,
      "OIML:ext-2" => external_dangling,
      "OIML:5.1" => normal_concept,
    }
    ->(ref) { table[Glossarist::ConceptRef.qualified_id(ref)] }
  end

  let(:hyperedge) do
    Glossarist::V3::GenericHyperedge.new(
      comprehensive: Glossarist::V3::ConceptRef.new(source: "OIML", id: "5.1"),
      members: [
        Glossarist::V3::GenericMember.new(
          ref: Glossarist::V3::ConceptRef.new(source: "OIML", id: "ext-1"),
        ),
        Glossarist::V3::GenericMember.new(
          ref: Glossarist::V3::ConceptRef.new(source: "OIML", id: "ext-2"),
        ),
        Glossarist::V3::GenericMember.new(
          ref: Glossarist::V3::ConceptRef.new(source: "OIML", id: "5.1"),
        ),
      ],
      criterion: { "eng" => "by example" },
    )
  end

  describe "#external_comprehensive?" do
    it "is false when the comprehensive is a normal concept" do
      expect(hyperedge.external_comprehensive?(resolver)).to be(false)
    end

    it "is true when the comprehensive resolves to status: external" do
      hyperedge.comprehensive = Glossarist::V3::ConceptRef.new(source: "OIML", id: "ext-1")
      expect(hyperedge.external_comprehensive?(resolver)).to be(true)
    end

    it "is false when no resolver is supplied (detection is opt-in)" do
      expect(hyperedge.external_comprehensive?).to be(false)
    end
  end

  describe "#external_members" do
    it "returns only members that resolve to status: external" do
      ext = hyperedge.external_members(resolver)
      expect(ext.length).to eq(2)
      expect(ext.map { |m| m.ref.id }).to contain_exactly("ext-1", "ext-2")
    end

    it "returns empty when no resolver is supplied" do
      expect(hyperedge.external_members).to eq([])
    end
  end

  describe "#dangling_externals?" do
    it "is true when at least one external lacks a provided_by edge" do
      # ext-1 has provided_by, ext-2 does not → dangles
      expect(hyperedge.dangling_externals?(resolver)).to be(true)
    end

    it "is false when every external has a provided_by edge" do
      external_dangling.related = [
        Glossarist::V3::RelatedConcept.new(
          type: "provided_by",
          ref: Glossarist::V3::ConceptRef.new(source: "OIML", id: "5.1"),
        ),
      ]
      expect(hyperedge.dangling_externals?(resolver)).to be(false)
    end

    it "is false when no resolver is supplied" do
      expect(hyperedge.dangling_externals?).to be(false)
    end

    it "flags external comprehensive without resolution" do
      hyperedge.comprehensive = Glossarist::V3::ConceptRef.new(source: "OIML", id: "ext-2")
      hyperedge.members = [
        Glossarist::V3::GenericMember.new(
          ref: Glossarist::V3::ConceptRef.new(source: "OIML", id: "5.1"),
        ),
        Glossarist::V3::GenericMember.new(
          ref: Glossarist::V3::ConceptRef.new(source: "OIML", id: "ext-1"),
        ),
      ]
      # ext-2 (comprehensive) has no provided_by → dangles
      expect(hyperedge.dangling_externals?(resolver)).to be(true)
    end
  end

  describe "OIML canonical case — (precision condition of measurement)" do
    # Per OIML V 2-200:2010 inventory: "(precision condition of measurement)"
    # is an ExternalConcept comprehensive with 2 hyperedges. The
    # parenthetical notation in ISO 704 diagrams signals external status.
    let(:precision_condition) do
      c = Glossarist::V3::ManagedConcept.new(
        data: Glossarist::V3::ManagedConceptData.new(id: "precision-condition"),
      )
      c.status = "external"
      c.related = [
        Glossarist::V3::RelatedConcept.new(
          type: "provided_by",
          ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "2.x"),
        ),
      ]
      c
    end

    let(:resolver_with_precision) do
      table = { "OIML:precision-condition" => precision_condition }
      ->(ref) { table[Glossarist::ConceptRef.qualified_id(ref)] }
    end

    it "detects the external comprehensive" do
      h = Glossarist::V3::GenericHyperedge.new(
        comprehensive: Glossarist::V3::ConceptRef.new(
          source: "OIML", id: "precision-condition",
        ),
        members: [
          Glossarist::V3::GenericMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "OIML", id: "2.6"),
          ),
          Glossarist::V3::GenericMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "OIML", id: "3.1"),
          ),
        ],
        criterion: { "eng" => "by participant type" },
      )
      expect(h.external_comprehensive?(resolver_with_precision)).to be(true)
      expect(h.dangling_externals?(resolver_with_precision)).to be(false)
    end
  end
end
