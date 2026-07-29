# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Glossarist::V3::RelationLoader do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  def write_file(path_str, content)
    full = File.join(tmpdir, path_str)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, content)
  end

  let(:partitive_yaml) do
    <<~YAML
      ---
      type: partitive_relation
      comprehensive:
        source: VIM
        id: '112-02-09'
      members:
        - ref: { source: VIM, id: '112-02-10' }
        - ref: { source: VIM, id: '112-03-26' }
      completeness: complete
      criterion:
        eng: measurement result composition
    YAML
  end

  let(:generic_yaml) do
    <<~YAML
      ---
      type: generic_relation
      comprehensive:
        source: OIML
        id: '5.1'
      members:
        - ref: { source: OIML, id: '5.13' }
        - ref: { source: OIML, id: '3.2' }
      criterion:
        eng: by realization medium
    YAML
  end

  describe ".load_all" do
    it "returns a hash keyed by comprehensive qualified_id" do
      write_file("relations/vim-112-02-09/foo.yaml", partitive_yaml)
      write_file("relations/oiml-5-1/bar.yaml", generic_yaml)

      all = described_class.load_all(File.join(tmpdir, "relations"))
      expect(all.keys).to contain_exactly("VIM:112-02-09", "OIML:5.1")
    end

    it "groups multiple relations under the same comprehensive id" do
      write_file("relations/example-116-01-01/physical.yaml", partitive_yaml)
      write_file("relations/example-116-01-01/functional.yaml",
                 partitive_yaml.sub("physical structure", "functional subsystem"))
      all = described_class.load_all(File.join(tmpdir, "relations"))
      expect(all["VIM:112-02-09"].length).to eq(2)
    end

    it "returns an empty hash for a non-existent directory" do
      all = described_class.load_all(File.join(tmpdir, "nope"))
      expect(all).to eq({})
    end

    it "loads each file as a typed relation" do
      write_file("relations/vim-112-02-09/foo.yaml", partitive_yaml)
      all = described_class.load_all(File.join(tmpdir, "relations"))
      rel = all["VIM:112-02-09"].first
      expect(rel).to be_a(Glossarist::V3::PartitiveRelation)
      expect(rel.members.length).to eq(2)
    end
  end

  describe ".load_for_concept" do
    it "returns relations only for the requested comprehensive id" do
      write_file("relations/vim-112-02-09/a.yaml", partitive_yaml)
      write_file("relations/oiml-5-1/b.yaml", generic_yaml)

      rels = described_class.load_for_concept(tmpdir, "vim-112-02-09")
      expect(rels.length).to eq(1)
      expect(rels.first).to be_a(Glossarist::V3::PartitiveRelation)
    end

    it "returns empty for an unknown id" do
      expect(described_class.load_for_concept(tmpdir, "does-not-exist")).to eq([])
    end
  end

  describe ".load_file" do
    it "returns a typed instance for a single file" do
      write_file("relations/vim-112-02-09/x.yaml", partitive_yaml)
      path = File.join(tmpdir, "relations/vim-112-02-09/x.yaml")
      rel = described_class.load_file(path)
      expect(rel).to be_a(Glossarist::V3::PartitiveRelation)
      expect(rel.comprehensive.id).to eq("112-02-09")
    end

    it "raises LoadError when `type` field is missing" do
      write_file("relations/x/y.yaml", "---\ncomprehensive: {}\n")
      expect { described_class.load_file(File.join(tmpdir, "relations/x/y.yaml")) }
        .to raise_error(Glossarist::V3::RelationLoader::LoadError, /missing required `type`/)
    end

    it "raises LoadError on an unknown type value" do
      write_file("relations/x/y.yaml", "---\ntype: bogus_relation\n")
      expect { described_class.load_file(File.join(tmpdir, "relations/x/y.yaml")) }
        .to raise_error(Glossarist::V3::RelationLoader::LoadError, /unknown type/)
    end

    it "loads generic relations as GenericRelation" do
      write_file("relations/oiml-5-1/z.yaml", generic_yaml)
      rel = described_class.load_file(File.join(tmpdir, "relations/oiml-5-1/z.yaml"))
      expect(rel).to be_a(Glossarist::V3::GenericRelation)
    end
  end

  describe "ConceptRef.qualified_id SSOT for keying" do
    it "uses VIM:1.2 form for source+id comprehensive" do
      write_file("relations/vim-112-02-09/foo.yaml", partitive_yaml)
      all = described_class.load_all(File.join(tmpdir, "relations"))
      expect(all.key?("VIM:112-02-09")).to be(true)
    end
  end
end
