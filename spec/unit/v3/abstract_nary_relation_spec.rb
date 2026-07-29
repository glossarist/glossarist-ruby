# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::AbstractNaryRelation do
  let(:ref) { Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.1") }

  describe "abstract enforcement" do
    it "raises NotImplementedError when instantiated directly" do
      expect { described_class.new(comprehensive: ref, members: []) }
        .to raise_error(NotImplementedError, /abstract/i)
    end

    it "is not registered as a Lutaml model" do
      # Concrete leaves are registered; abstract bases are NOT. The
      # public resolve_model API raises on unknown ids — that's how
      # we verify the absence.
      expect { Glossarist::V3::Configuration.resolve_model(:abstract_nary_relation) }
        .to raise_error(StandardError)
      expect { Glossarist::V3::Configuration.resolve_model(:concept_system_member) }
        .to raise_error(StandardError)
      # Sanity check: leaves ARE resolvable.
      expect(Glossarist::V3::Configuration.resolve_model(:partitive_relation))
        .to eq(Glossarist::V3::PartitiveRelation)
      expect(Glossarist::V3::Configuration.resolve_model(:generic_relation))
        .to eq(Glossarist::V3::GenericRelation)
    end
  end

  describe "concrete subclasses" do
    it "PartitiveRelation can be instantiated" do
      expect(Glossarist::V3::PartitiveRelation.new(
               comprehensive: ref,
               members: [Glossarist::V3::PartitiveMember.new(
                 ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2"),
               )],
             )).to be_a(described_class)
    end

    it "GenericRelation can be instantiated" do
      expect(Glossarist::V3::GenericRelation.new(
               comprehensive: ref,
               members: [Glossarist::V3::GenericMember.new(
                 ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2"),
               )],
             )).to be_a(described_class)
    end
  end

  describe "shared validations (inherited by leaves)" do
    it "validates comprehensive is non-empty" do
      rel = Glossarist::V3::PartitiveRelation.new(
        comprehensive: Glossarist::V3::ConceptRef.new,
        members: [Glossarist::V3::PartitiveMember.new(ref: ref)],
      )
      expect { rel.validate! }.to raise_error(ArgumentError, /comprehensive/)
    end

    it "validates members has >=2 entries" do
      rel = Glossarist::V3::PartitiveRelation.new(
        comprehensive: ref,
        members: [Glossarist::V3::PartitiveMember.new(ref: ref)],
      )
      expect { rel.validate! }.to raise_error(ArgumentError, /members/)
    end

    it "validates against self-loops" do
      rel = Glossarist::V3::PartitiveRelation.new(
        comprehensive: ref,
        members: [
          Glossarist::V3::PartitiveMember.new(ref: ref),
          Glossarist::V3::PartitiveMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2"),
          ),
        ],
      )
      expect { rel.validate! }.to raise_error(ArgumentError, /comprehensive/)
    end

    it "validates completeness enum" do
      rel = Glossarist::V3::PartitiveRelation.new(
        comprehensive: ref,
        members: [
          Glossarist::V3::PartitiveMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2"),
          ),
          Glossarist::V3::PartitiveMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.3"),
          ),
        ],
        completeness: "bogus",
      )
      expect { rel.validate! }.to raise_error(ArgumentError, /completeness/)
    end
  end

  describe "shared predicates" do
    let(:rel) do
      Glossarist::V3::PartitiveRelation.new(
        comprehensive: ref,
        members: [
          Glossarist::V3::PartitiveMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2"),
          ),
          Glossarist::V3::PartitiveMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.3"),
          ),
        ],
      )
    end

    it "#complete? is true when completeness is complete" do
      expect(rel).to be_complete
      expect(rel).not_to be_partial
    end

    it "#partial? is true when completeness is partial" do
      rel.completeness = "partial"
      expect(rel).to be_partial
      expect(rel).not_to be_complete
    end

    it "#coordinate? is true when members.length >= 2" do
      expect(rel).to be_coordinate
    end
  end
end
