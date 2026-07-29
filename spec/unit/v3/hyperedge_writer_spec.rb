# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe "Per-file hyperedge round-trip (write → read)" do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:relations_dir) { File.join(tmpdir, "relations") }

  let(:oiml_5_1_relations) do
    # The canonical OIML V 2-200:2010 multi-hyperedge case.
    %w[by-realization-medium by-calibration-role by-governance-level
       by-metrological-hierarchy by-reference-working by-travel].map do |slug|
      Glossarist::V3::GenericHyperedge.new(
        comprehensive: Glossarist::V3::ConceptRef.new(source: "OIML", id: "5.1"),
        members: [
          Glossarist::V3::GenericMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "OIML", id: "5.13"),
          ),
          Glossarist::V3::GenericMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "OIML", id: "3.2"),
          ),
        ],
        completeness: "complete",
        criterion: { "eng" => slug.tr("-", " ") },
      )
    end
  end

  it "writes 6 hyperedges to relations/oiml-5-1/<slug>.yaml" do
    Glossarist::V3::HyperedgeWriter.write_all(oiml_5_1_relations, relations_dir)
    files = Dir.glob(File.join(relations_dir, "oiml-5-1", "*.yaml")).sort
    expect(files.length).to eq(6)
    expected_slugs = %w[
      by-realization-medium by-calibration-role by-governance-level
      by-metrological-hierarchy by-reference-working by-travel
    ].map { |s| File.join(relations_dir, "oiml-5-1", "#{s}.yaml") }.sort
    expect(files).to eq(expected_slugs)
  end

  it "round-trips each hyperedge through write → load → same identity" do
    oiml_5_1_relations.each do |original|
      path = Glossarist::V3::HyperedgeWriter.write(original, relations_dir)
      loaded = Glossarist::V3::RelationLoader.load_file(path)

      expect(loaded).to be_a(Glossarist::V3::GenericHyperedge)
      expect(loaded.comprehensive.id).to eq(original.comprehensive.id)
      expect(loaded.comprehensive.source).to eq(original.comprehensive.source)
      expect(loaded.criterion).to eq(original.criterion)
      expect(loaded.members.map { |m| m.ref.id })
        .to eq(original.members.map { |m| m.ref.id })
      expect(loaded.file_id).to eq(original.derived_file_id)
    end
  end

  it "preserves $id on load → write back to same path" do
    # Write once
    original = oiml_5_1_relations.first
    path1 = Glossarist::V3::HyperedgeWriter.write(original, relations_dir)
    # Load — should preserve $id
    loaded = Glossarist::V3::RelationLoader.load_file(path1)
    expect(loaded.file_id).to eq("oiml-5-1/by-realization-medium")
    # Modify something unrelated (e.g., completeness)
    loaded.completeness = "partial"
    # Write back — should go to same file because $id is preserved
    path2 = Glossarist::V3::HyperedgeWriter.write(loaded, relations_dir)
    expect(path2).to eq(path1)
  end

  it "writes through GlossaryStore#add_relation" do
    dir = File.join(tmpdir, "dataset")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "metadata.yaml"), "schema_version: '3'\n")
    FileUtils.mkdir_p(File.join(dir, "concepts"))
    File.write(File.join(dir, "concepts", "5-1.yaml"),
               "data:\n  id: '5.1'\nschema_version: '3'\n")

    store = Glossarist::GlossaryStore.new
    store.load(dir)

    path = store.add_relation(oiml_5_1_relations.first)
    expect(path).to eq(File.join(dir, "relations", "oiml-5-1", "by-realization-medium.yaml"))
    expect(File.exist?(path)).to be(true)

    # Reload — the relation should appear in store.relations
    store2 = Glossarist::GlossaryStore.new
    store2.load(dir)
    expect(store2.relations.length).to eq(1)
    expect(store2.relations.first).to be_a(Glossarist::V3::GenericHyperedge)
  end

  it "writes through GlossaryStore#save_directory (relations subdirectory)" do
    src = File.join(tmpdir, "src")
    FileUtils.mkdir_p(src)
    File.write(File.join(src, "metadata.yaml"), "schema_version: '3'\n")
    FileUtils.mkdir_p(File.join(src, "concepts"))
    File.write(File.join(src, "concepts", "5-1.yaml"),
               "data:\n  id: '5.1'\nschema_version: '3'\n")

    store = Glossarist::GlossaryStore.new
    store.load(src)
    # Inject relations directly into the lazy-loaded cache, then save
    store.relations  # prime the cache
    store.instance_variable_set(:@relations, oiml_5_1_relations)

    dest = File.join(tmpdir, "dest")
    store.save_directory(dest)

    files = Dir.glob(File.join(dest, "relations", "oiml-5-1", "*.yaml")).sort
    expect(files.length).to eq(6)
  end

  describe "edge cases" do
    it "derives structural slug when criterion has no English" do
      h = Glossarist::V3::PartitiveHyperedge.new(
        comprehensive: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.1"),
        members: [
          Glossarist::V3::PartitiveMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2"),
          ),
          Glossarist::V3::PartitiveMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.3"),
          ),
        ],
        criterion: { "fra" => "structure physique" },
      )
      expect(h.criterion_slug).to match(/\Adecomposition-[0-9a-f]{6}\z/)
      expect(h.derived_file_id).to start_with("vim-1-1/decomposition-")
    end

    it "rejects write when comprehensive is empty" do
      h = Glossarist::V3::PartitiveHyperedge.new(
        comprehensive: Glossarist::V3::ConceptRef.new,
        members: [
          Glossarist::V3::PartitiveMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2"),
          ),
          Glossarist::V3::PartitiveMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.3"),
          ),
        ],
      )
      expect { Glossarist::V3::HyperedgeWriter.write(h, relations_dir) }
        .to raise_error(Glossarist::V3::HyperedgeWriter::WriteError)
    end

    it "rejects write of non-hyperedge object" do
      expect { Glossarist::V3::HyperedgeWriter.write("not a hyperedge", relations_dir) }
        .to raise_error(Glossarist::V3::HyperedgeWriter::WriteError)
    end
  end
end
