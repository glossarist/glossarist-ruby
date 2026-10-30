# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

# glossarist-data-iev keeps the split layout inside concepts/:
#   concepts/concept/<id>.yaml + concepts/localized_concept/<uuid>.yaml
# `glossarist validate` and `glossarist package` both load through
# GlossaryStore, which only knew the split layout at the dataset root.
RSpec.describe "split layout under concepts/" do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  def concept_yaml(id, uuid)
    <<~YAML
      ---
      data:
        identifier: "#{id}"
        localized_concepts:
          eng: #{uuid}
      status: valid
      schema_version: '3'
      id: #{uuid.sub(/^./, 'c')}
    YAML
  end

  def l10n_yaml(uuid, term)
    <<~YAML
      ---
      data:
        definition:
        - content: a definition of #{term}
        terms:
        - type: expression
          normative_status: preferred
          designation: #{term}
        language_code: eng
        entry_status: valid
      id: #{uuid}
    YAML
  end

  def write(rel, content)
    path = File.join(tmpdir, rel)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content, encoding: "utf-8")
  end

  def write_split(id, uuid, term)
    write("concepts/concept/#{id}.yaml", concept_yaml(id, uuid))
    write("concepts/localized_concept/#{uuid}.yaml", l10n_yaml(uuid, term))
  end

  # Same concept, grouped: concept document then localization documents.
  def grouped_yaml(id, uuid, term)
    "#{concept_yaml(id, uuid)}\n#{l10n_yaml(uuid, term)}"
  end

  describe Glossarist::GlossaryStore do
    it "loads concepts and localizations from concepts/concept + concepts/localized_concept" do
      write_split("1-1", "11111111-1111-1111-1111-111111111111", "alpha")
      write_split("1-2", "22222222-2222-2222-2222-222222222222", "beta")

      concepts = described_class.new.load(tmpdir).concepts

      expect(concepts.map { |c| c.data.id }).to contain_exactly("1-1", "1-2")
      expect(concepts.map { |c| c.localization("eng").data.terms.first.designation })
        .to contain_exactly("alpha", "beta")
    end

    it "still loads grouped concepts/*.yaml files" do
      write("concepts/1-1.yaml",
            grouped_yaml("1-1", "11111111-1111-1111-1111-111111111111", "alpha"))

      store = described_class.new.load(tmpdir)

      expect(store.concepts.map { |c| c.data.id }).to eq(["1-1"])
      expect(store.concepts.first.localization("eng")).not_to be_nil
    end

    it "loads a grouped file for an id the split layout lacks" do
      write_split("1-1", "11111111-1111-1111-1111-111111111111", "alpha")
      write("concepts/1-2.yaml",
            grouped_yaml("1-2", "22222222-2222-2222-2222-222222222222", "beta"))

      ids = described_class.new.load(tmpdir).concepts.map { |c| c.data.id }

      expect(ids).to contain_exactly("1-1", "1-2")
    end

    it "keeps the split concept and warns once when a grouped file duplicates it" do
      write_split("1-1", "11111111-1111-1111-1111-111111111111", "alpha")
      write("concepts/1-1.yaml",
            grouped_yaml("1-1", "11111111-1111-1111-1111-111111111111", "alpha"))

      store = described_class.new
      expect { store.load(tmpdir) }
        .to output(/ignored 1 grouped file.*1-1\.yaml/).to_stderr
      expect(store.concepts.map { |c| c.data.id }).to eq(["1-1"])
    end
  end

  describe Glossarist::ConceptValidator do
    it "validates the split layout without orphaned-localization warnings" do
      write_split("1-1", "11111111-1111-1111-1111-111111111111", "alpha")

      result = described_class.new(tmpdir).validate_all

      expect(result.errors).to be_empty
      expect(result.issues.map(&:code)).not_to include("GLS-019")
    end
  end

  describe Glossarist::GcrPackage do
    it "packages the split layout under concepts/" do
      write_split("1-1", "11111111-1111-1111-1111-111111111111", "alpha")
      write_split("1-2", "22222222-2222-2222-2222-222222222222", "beta")
      out = File.join(tmpdir, "out.gcr")

      described_class.create_from_directory(
        tmpdir, output: out, shortname: "t", version: "0.0.0"
      )

      package = described_class.load(out)
      expect(package.concepts.map { |c| c.data.id })
        .to contain_exactly("1-1", "1-2")
    end
  end
end
