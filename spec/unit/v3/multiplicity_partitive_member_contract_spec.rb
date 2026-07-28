# frozen_string_literal: true

require "spec_helper"

# Cross-cutting contract between the orthogonal-dimensions model
# (PartitiveMember: presence + count + is_delimiting) and the derived
# display utility (Multiplicity: maps the dimensions to ISO 704 names).
#
# The model is the SSOT for what dimensions are valid; the utility is
# the SSOT for the (presence, count) → name mapping. They must agree
# on the 5 valid combinations and the 1 invalid combination.

RSpec.describe "Multiplicity ↔ PartitiveMember contract" do
  let(:ref) { Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2") }

  describe "for each valid combination in NAME_BY_PAIR" do
    Glossarist::V3::Multiplicity::NAME_BY_PAIR.each do |(presence, count), name|
      it "PartitiveMember accepts (#{presence}, #{count}) and Multiplicity maps it to '#{name}'" do
        member = Glossarist::V3::PartitiveMember.new(
          ref: ref, presence: presence, count: count,
        )
        expect { member.validate! }.not_to raise_error
        expect(Glossarist::V3::Multiplicity.multiplicity_from_pair(presence, count))
          .to eq(name)
      end
    end
  end

  describe "round-trip: pair → name → pair" do
    Glossarist::V3::Multiplicity::NAME_BY_PAIR.each do |(presence, count), name|
      it "(#{presence}, #{count}) → '#{name}' → (#{presence}, #{count})" do
        round_trip = Glossarist::V3::Multiplicity.pair_from_multiplicity(name)
        expect(round_trip).to eq(presence: presence, count: count)
      end
    end
  end

  describe "invalid combination rejection" do
    it "PartitiveMember rejects (optional, at_least_one) — matches Multiplicity" do
      expect { Glossarist::V3::PartitiveMember.new(ref: ref, presence: "optional", count: "at_least_one").validate! }
        .to raise_error(ArgumentError, /collapses to optional \+ multiple/)

      expect { Glossarist::V3::Multiplicity.multiplicity_from_pair("optional", "at_least_one") }
        .to raise_error(ArgumentError, /collapses to optional \+ multiple/)
    end
  end

  describe "DEFAULT constants agree" do
    it "PartitiveMember defaults match Multiplicity.pair_from_multiplicity(DEFAULT_MULTIPLICITY)" do
      member = Glossarist::V3::PartitiveMember.new(ref: ref)
      pair = Glossarist::V3::Multiplicity.pair_from_multiplicity(
        Glossarist::V3::Multiplicity::DEFAULT_MULTIPLICITY,
      )
      expect(member.presence).to eq(pair[:presence])
      expect(member.count).to eq(pair[:count])
    end

    it "Multiplicity.DEFAULT_MULTIPLICITY is what PartitiveMember defaults produce" do
      member = Glossarist::V3::PartitiveMember.new(ref: ref)
      expect(Glossarist::V3::Multiplicity.multiplicity_from_pair(member.presence, member.count))
        .to eq(Glossarist::V3::Multiplicity::DEFAULT_MULTIPLICITY)
    end
  end

  describe "cardinality of valid combinations" do
    it "is exactly 5 (the cross product of presence × count minus the redundant combo)" do
      # 2 presences × 3 counts = 6 combinations
      # 1 invalid (optional + at_least_one collapses to optional + multiple)
      # → 5 valid
      all_combos = Glossarist::GlossaryDefinition::PARTITIVE_PRESENCE_VALUES
        .product(Glossarist::GlossaryDefinition::PARTITIVE_COUNT_VALUES)
      valid = all_combos.count do |p, c|
        Glossarist::V3::Multiplicity::NAME_BY_PAIR.key?([p, c])
      end
      expect(valid).to eq(5)
    end
  end
end
