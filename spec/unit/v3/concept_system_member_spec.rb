# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::ConceptSystemMember do
  let(:ref) { Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2") }

  describe "abstract enforcement" do
    it "raises NotImplementedError when instantiated directly" do
      expect { described_class.new(ref: ref) }
        .to raise_error(NotImplementedError, /abstract/i)
    end

    it "PartitiveMember can be instantiated" do
      expect(Glossarist::V3::PartitiveMember.new(ref: ref)).to be_a(described_class)
    end

    it "GenericMember can be instantiated" do
      expect(Glossarist::V3::GenericMember.new(ref: ref)).to be_a(described_class)
    end
  end

  describe "MECE dimensions (inherited by leaves)" do
    it "defaults to required/exactly_one" do
      m = Glossarist::V3::PartitiveMember.new(ref: ref)
      expect(m.presence).to eq("required")
      expect(m.count).to eq("exactly_one")
      expect(m.is_delimiting).to be(false)
    end

    it "rejects invalid presence value" do
      m = Glossarist::V3::PartitiveMember.new(ref: ref, presence: "maybe")
      expect { m.validate! }.to raise_error(ArgumentError, /invalid value/)
    end

    it "rejects invalid count value" do
      m = Glossarist::V3::PartitiveMember.new(ref: ref, count: "many")
      expect { m.validate! }.to raise_error(ArgumentError, /invalid value/)
    end

    it "delegates the combination check to Multiplicity (DRY)" do
      m = Glossarist::V3::PartitiveMember.new(ref: ref, presence: "optional", count: "at_least_one")
      expect { m.validate! }
        .to raise_error(ArgumentError, /collapses to optional \+ multiple/)

      m2 = Glossarist::V3::GenericMember.new(ref: ref, presence: "optional", count: "at_least_one")
      expect { m2.validate! }
        .to raise_error(ArgumentError, /collapses to optional \+ multiple/)
    end

    it "rejects empty ref" do
      m = Glossarist::V3::PartitiveMember.new(ref: Glossarist::V3::ConceptRef.new)
      expect { m.validate! }.to raise_error(ArgumentError, /non-empty ConceptRef/)
    end
  end

  describe "predicates" do
    it "#required? reflects presence" do
      expect(Glossarist::V3::PartitiveMember.new(ref: ref, presence: "required")).to be_required
      expect(Glossarist::V3::PartitiveMember.new(ref: ref, presence: "optional")).not_to be_required
    end

    it "#optional? reflects presence" do
      expect(Glossarist::V3::PartitiveMember.new(ref: ref, presence: "optional")).to be_optional
    end

    it "#delimiting? reflects is_delimiting" do
      expect(Glossarist::V3::PartitiveMember.new(ref: ref, is_delimiting: true)).to be_delimiting
      expect(Glossarist::V3::PartitiveMember.new(ref: ref, is_delimiting: false)).not_to be_delimiting
    end
  end
end
