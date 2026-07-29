# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Glossarist::GlossaryStore, "#relations" do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  def write_concept(id)
    dir = File.join(tmpdir, "concepts")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "#{id}.yaml"), <<~YAML)
      ---
      data:
        id: #{id}
      schema_version: "3"
    YAML
  end

  def write_relation(comprehensive_id, slug, type: "partitive_relation")
    dir = File.join(tmpdir, "relations", comprehensive_id)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "#{slug}.yaml"), <<~YAML)
      ---
      type: #{type}
      comprehensive:
        source: VIM
        id: '#{comprehensive_id}'
      members:
        - ref: { source: VIM, id: '1.2' }
        - ref: { source: VIM, id: '1.3' }
      completeness: complete
      criterion:
        eng: #{slug}
    YAML
  end

  it "returns an empty array when the dataset has no relations/ dir" do
    write_concept("x")
    store = Glossarist::GlossaryStore.new
    store.load(tmpdir)
    expect(store.relations).to eq([])
  end

  it "loads all relations via V3::RelationLoader" do
    write_concept("112-02-09")
    write_concept("5.1")
    write_relation("112-02-09", "physical-structure")
    write_relation("5.1", "by-medium", type: "generic_relation")

    store = Glossarist::GlossaryStore.new
    store.load(tmpdir)
    expect(store.relations.length).to eq(2)
    types = store.relations.map(&:class).map(&:name)
    expect(types).to include("Glossarist::V3::PartitiveRelation")
    expect(types).to include("Glossarist::V3::GenericRelation")
  end

  it "memoizes the result" do
    write_concept("x")
    write_relation("x", "foo")
    store = Glossarist::GlossaryStore.new
    store.load(tmpdir)
    first = store.relations
    second = store.relations
    expect(first.object_id).to eq(second.object_id)
  end

  describe "#relations_for" do
    it "filters by comprehensive qualified_id string" do
      write_concept("112-02-09")
      write_concept("5.1")
      write_relation("112-02-09", "physical")
      write_relation("5.1", "by-medium")

      store = Glossarist::GlossaryStore.new
      store.load(tmpdir)
      expect(store.relations_for("VIM:112-02-09").length).to eq(1)
      expect(store.relations_for("VIM:5.1").length).to eq(1)
      expect(store.relations_for("VIM:missing")).to eq([])
    end

    it "accepts a ConceptRef instead of a string" do
      write_concept("112-02-09")
      write_relation("112-02-09", "physical")

      store = Glossarist::GlossaryStore.new
      store.load(tmpdir)
      ref = Glossarist::ConceptRef.new(source: "VIM", id: "112-02-09")
      expect(store.relations_for(ref).length).to eq(1)
    end
  end
end
