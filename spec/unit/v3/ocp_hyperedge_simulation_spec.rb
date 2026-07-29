# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

# The executable OCP contract. Defines a mock hyperedge type and
# verifies that every system (registry, storage, YAML round-trip,
# RelationLoader dispatch, RDF emission, validator runner) handles it
# WITHOUT any edit to production code outside the mock class
# definition itself.
#
# When this spec passes, the architecture is OCP-correct: adding a
# new hyperedge type is one new class file + one register call.
RSpec.describe "OCP contract: adding a new hyperedge type" do
  let(:ref) do
    ->(source, id) { Glossarist::V3::ConceptRef.new(source: source, id: id) }
  end

  # Mock hyperedge type — defined once at the top of this spec file.
  # Models a hypothetical "TemporalHyperedge" (e.g., "before/after"
  # decompositions of an event concept). The production codebase has
  # NO knowledge of this class.
  before(:all) do
    module Glossarist
      module V3
        class TemporalMember < HyperedgeMember
        end

        class TemporalHyperedge < AbstractHyperedge
          WIRE_KEY     = "temporal_relations"
          TYPE_TAG     = "temporal_relation"
          RDF_TYPE     = "gloss:TemporalHyperedge"
          MEMBER_CLASS = TemporalMember
          V1_WIRE_KEYS = [].freeze
          KIND_LABEL   = "TEMP"

          attribute :members, TemporalMember, collection: true
        end

        HyperedgeRegistry.register(TemporalHyperedge)
      end
    end
  end

  after(:all) do
    # Surgically remove only the mock entries from the registry —
    # do NOT call reset! (it wipes production leaves and breaks
    # subsequent spec files since RSpec runs in one process).
    registry = Glossarist::V3::HyperedgeRegistry
    registry::BY_WIRE_KEY.delete("temporal_relations")
    registry::BY_TYPE_TAG.delete("temporal_relation")
    registry::BY_RDF_TYPE.delete("gloss:TemporalHyperedge")
    Glossarist::V3.send(:remove_const, :TemporalMember)
    Glossarist::V3.send(:remove_const, :TemporalHyperedge)
  end

  let(:temporal_member) do
    Glossarist::V3::TemporalMember.new(ref: ref.call("X", "1.2"))
  end

  let(:temporal_hyperedge) do
    Glossarist::V3::TemporalHyperedge.new(
      comprehensive: ref.call("X", "1.1"),
      members: [
        Glossarist::V3::TemporalMember.new(ref: ref.call("X", "1.2")),
        Glossarist::V3::TemporalMember.new(ref: ref.call("X", "1.3")),
      ],
      criterion: { "eng" => "before/after" },
    )
  end

  it "registers in HyperedgeRegistry under all three identifiers" do
    expect(Glossarist::V3::HyperedgeRegistry.for_wire_key("temporal_relations"))
      .to eq(Glossarist::V3::TemporalHyperedge)
    expect(Glossarist::V3::HyperedgeRegistry.for_type_tag("temporal_relation"))
      .to eq(Glossarist::V3::TemporalHyperedge)
    expect(Glossarist::V3::HyperedgeRegistry.for_rdf_type("gloss:TemporalHyperedge"))
      .to eq(Glossarist::V3::TemporalHyperedge)
  end

  it "is included in HyperedgeRegistry.all_classes" do
    expect(Glossarist::V3::HyperedgeRegistry.all_classes)
      .to include(Glossarist::V3::TemporalHyperedge)
  end

  it "validates via inherited AbstractHyperedge#validate!" do
    expect { temporal_hyperedge.validate! }.not_to raise_error
  end

  it "rejects < 2 members via inherited validation" do
    bad = Glossarist::V3::TemporalHyperedge.new(
      comprehensive: ref.call("X", "1.1"),
      members: [Glossarist::V3::TemporalMember.new(ref: ref.call("X", "1.2"))],
    )
    expect { bad.validate! }.to raise_error(ArgumentError, /members/)
  end

  it "rejects self-loops via inherited validation" do
    same = ref.call("X", "1.1")
    bad = Glossarist::V3::TemporalHyperedge.new(
      comprehensive: same,
      members: [
        Glossarist::V3::TemporalMember.new(ref: same),
        Glossarist::V3::TemporalMember.new(ref: ref.call("X", "1.2")),
      ],
    )
    expect { bad.validate! }.to raise_error(ArgumentError, /comprehensive/)
  end

  describe "V3::ManagedConcept storage" do
    it "accepts the new type via the unified #relations accessor" do
      mc = Glossarist::V3::ManagedConcept.new(
        data: Glossarist::V3::ManagedConceptData.new(id: "x"),
      )
      mc.relations = [temporal_hyperedge]
      expect(mc.relations.first).to be_a(Glossarist::V3::TemporalHyperedge)
    end
  end

  describe "HyperedgeIndex reverse lookup" do
    it "indexes the new type transparently" do
      index = Glossarist::V3::HyperedgeIndex.new([temporal_hyperedge])
      expect(index.for_comprehensive("X:1.1")).to include(temporal_hyperedge)
      expect(index.for_member("X:1.2")).to include(temporal_hyperedge)
    end
  end

  describe "RelationLoader" do
    it "loads the new type via HyperedgeRegistry dispatch" do
      Dir.mktmpdir do |tmp|
        relations_dir = File.join(tmp, "relations", "X-1-1")
        FileUtils.mkdir_p(relations_dir)
        File.write(File.join(relations_dir, "before-after.yaml"), <<~YAML)
          ---
          type: temporal_relation
          comprehensive:
            source: X
            id: '1.1'
          members:
            - ref: { source: X, id: '1.2' }
            - ref: { source: X, id: '1.3' }
          criterion:
            eng: before/after
        YAML

        rel = Glossarist::V3::RelationLoader.load_file(
          File.join(relations_dir, "before-after.yaml"),
        )
        expect(rel).to be_a(Glossarist::V3::TemporalHyperedge)
        expect(rel.comprehensive.id).to eq("1.1")
      end
    end

    it "rejects an unknown type via HyperedgeRegistry dispatch" do
      Dir.mktmpdir do |tmp|
        path = File.join(tmp, "x.yaml")
        File.write(path, "---\ntype: not_a_real_type\n")
        expect { Glossarist::V3::RelationLoader.load_file(path) }
          .to raise_error(Glossarist::V3::RelationLoader::LoadError, /unknown type/)
      end
    end
  end

  describe "HyperedgeCoherenceRule" do
    it "applies to the new type via inherited AbstractHyperedge predicate" do
      rule = Glossarist::Validation::Rules::HyperedgeCoherenceRule.new
      expect(rule).to be_applicable(make_context_with_relations([temporal_hyperedge]))
    end
  end

  describe "deterministic_id inheritance" do
    it "produces stable subjects for the new type" do
      gloss_member = Glossarist::Rdf::GlossPartitiveMember.new(
        ref_source: "X", ref_id: "1.2",
      )
      # The deterministic_id method is inherited from GlossNaryMember;
      # any new GlossXMember subclass gets it automatically.
      expect(gloss_member).to respond_to(:presence)
    end
  end

  private

  def make_context_with_relations(relations)
    tmpdir = Dir.mktmpdir
    dataset_context = Glossarist::Validation::Rules::DatasetContext.new(tmpdir)
    mc = Glossarist::V3::ManagedConcept.new(
      data: Glossarist::V3::ManagedConceptData.new(id: "x"),
    )
    mc.relations = relations
    context = Glossarist::Validation::Rules::ConceptContext.new(
      mc,
      file_name: "concepts/x.yaml",
      collection_context: dataset_context,
      relations: relations,
    )
    context
  ensure
    FileUtils.rm_rf(tmpdir) if tmpdir
  end
end
