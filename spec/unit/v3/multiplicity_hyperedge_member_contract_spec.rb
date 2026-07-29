# frozen_string_literal: true

require "spec_helper"

# Cross-cutting contract between the orthogonal-dimensions model
# (HyperedgeMember: presence + count + is_delimiting) and the
# derived display utility (Multiplicity: maps the dimensions to ISO
# 704 names). Both PartitiveMember and GenericMember inherit from
# HyperedgeMember, so this contract applies to both.
#
# The model is the SSOT for what dimensions are valid; the utility is
# the SSOT for the (presence, count) → name mapping. They must agree
# on the 5 valid combinations and the 1 invalid combination.

RSpec.describe "Multiplicity ↔ HyperedgeMember contract" do
  let(:ref) { Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2") }

  [Glossarist::V3::PartitiveMember, Glossarist::V3::GenericMember].each do |klass|
    describe "for #{klass.name}" do
      let(:member) { klass.new(ref: ref) }

      it "inherits HyperedgeMember" do
        expect(member).to be_a(Glossarist::V3::HyperedgeMember)
      end

      describe "for each valid combination in NAME_BY_PAIR" do
        Glossarist::V3::Multiplicity::NAME_BY_PAIR.each do |(presence, count), name|
          it "accepts (#{presence}, #{count}) and Multiplicity maps it to '#{name}'" do
            m = klass.new(ref: ref, presence: presence, count: count)
            expect { m.validate! }.not_to raise_error
            expect(Glossarist::V3::Multiplicity.multiplicity_from_pair(presence, count))
              .to eq(name)
          end
        end
      end

      it "rejects (optional, at_least_one) — matches Multiplicity error" do
        expect { klass.new(ref: ref, presence: "optional", count: "at_least_one").validate! }
          .to raise_error(ArgumentError, /collapses to optional \+ multiple/)
      end

      it "defaults to presence=required, count=exactly_one (DEFAULT_MULTIPLICITY)" do
        pair = Glossarist::V3::Multiplicity.pair_from_multiplicity(
          Glossarist::V3::Multiplicity::DEFAULT_MULTIPLICITY,
        )
        expect(member.presence).to eq(pair[:presence])
        expect(member.count).to eq(pair[:count])
        expect(Glossarist::V3::Multiplicity.multiplicity_from_pair(member.presence, member.count))
          .to eq(Glossarist::V3::Multiplicity::DEFAULT_MULTIPLICITY)
      end
    end
  end

  describe "cardinality of valid combinations" do
    it "is exactly 5 (the cross product of presence × count minus the redundant combo)" do
      all_combos = Glossarist::GlossaryDefinition::MEMBER_PRESENCE_VALUES
        .product(Glossarist::GlossaryDefinition::MEMBER_COUNT_VALUES)
      valid = all_combos.count do |p, c|
        Glossarist::V3::Multiplicity::NAME_BY_PAIR.key?([p, c])
      end
      expect(valid).to eq(5)
    end
  end
end
