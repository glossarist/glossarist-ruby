# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "zip"

RSpec.describe Glossarist::GlossaryStore do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:store) { described_class.new }

  let(:concept_a_yaml) do
    <<~YAML
      ---
      data:
        identifier: "3.1.1"
        localized_concepts:
          eng: l10n-aaa-eng
      status: valid
      schema_version: '3'
      id: aaa-111
      ---
      data:
        definition:
        - content: Test definition A
        terms:
        - type: expression
          normative_status: preferred
          designation: term alpha
        language_code: eng
        entry_status: valid
      id: l10n-aaa-eng
    YAML
  end

  let(:concept_b_yaml) do
    <<~YAML
      ---
      data:
        identifier: "3.1.2"
        localized_concepts:
          eng: l10n-bbb-eng
          fra: l10n-bbb-fra
      status: valid
      schema_version: '3'
      id: bbb-222
      ---
      data:
        definition:
        - content: Test definition B
        terms:
        - type: expression
          normative_status: preferred
          designation: term beta
        language_code: eng
        entry_status: valid
      id: l10n-bbb-eng
      ---
      data:
        definition:
        - content: Definition B en francais
        terms:
        - type: expression
          normative_status: preferred
          designation: terme beta
        language_code: fra
        entry_status: valid
      id: l10n-bbb-fra
    YAML
  end

  def create_glossary_dir(dir)
    concepts_dir = File.join(dir, "concepts")
    FileUtils.mkdir_p(concepts_dir)

    File.write(File.join(concepts_dir, "aaa-111.yaml"), concept_a_yaml,
               encoding: "utf-8")
    File.write(File.join(concepts_dir, "bbb-222.yaml"), concept_b_yaml,
               encoding: "utf-8")

    File.write(File.join(dir, "register.yaml"),
               "---\nname: Test Glossary\nsubregisters:\n  eng:\n",
               encoding: "utf-8")

    File.write(File.join(dir, "metadata.yaml"), <<~YAML, encoding: "utf-8")
      ---
      shortname: test-glossary
      version: 1.0.0
      schema_version: '3'
      concept_count: 2
    YAML

    bib = Glossarist::BibliographyData.new
    bib.entries << Glossarist::BibliographyEntry.new(
      id: "ref_1", reference: "ISO 704", title: "Terminology work",
    )
    File.write(File.join(dir, "bibliography.yaml"), bib.to_yaml,
               encoding: "utf-8")

    dir
  end

  let(:glossary_dir) { create_glossary_dir(File.join(tmpdir, "glossary")) }

  describe "#load_directory" do
    it "loads concepts from a GCR concepts/ directory" do
      store.load_directory(glossary_dir)
      expect(store.concept_count).to eq(2)
    end

    it "loads metadata from metadata.yaml" do
      store.load_directory(glossary_dir)
      expect(store.metadata).to be_a(Glossarist::GcrMetadata)
      expect(store.metadata.shortname).to eq("test-glossary")
    end

    it "loads register data from register.yaml" do
      store.load_directory(glossary_dir)
      expect(store.register_data).to be_a(Glossarist::RegisterData)
      expect(store.register_data.name).to eq("Test Glossary")
    end

    it "loads bibliography from bibliography.yaml" do
      store.load_directory(glossary_dir)
      expect(store.bibliography).to be_a(Glossarist::BibliographyData)
      expect(store.bibliography.entries.length).to eq(1)
    end

    it "handles missing optional files gracefully" do
      dir = File.join(tmpdir, "minimal")
      concepts_dir = File.join(dir, "concepts")
      FileUtils.mkdir_p(concepts_dir)
      File.write(File.join(concepts_dir, "aaa-111.yaml"), concept_a_yaml,
                 encoding: "utf-8")

      store.load_directory(dir)
      expect(store.concept_count).to eq(1)
      expect(store.metadata).to be_nil
      expect(store.register_data).to be_nil
      expect(store.bibliography).to be_nil
    end
  end

  describe "#load_zip" do
    it "loads from a ZIP archive" do
      zip_path = create_test_zip(glossary_dir, File.join(tmpdir, "test.gcr"))
      store.load_zip(zip_path)
      expect(store.concept_count).to eq(2)
      expect(store.metadata).not_to be_nil
    end
  end

  describe "#load" do
    it "auto-detects directory from path" do
      store.load(glossary_dir)
      expect(store.concept_count).to eq(2)
    end

    it "auto-detects ZIP from .gcr extension" do
      zip_path = create_test_zip(glossary_dir, File.join(tmpdir, "test.gcr"))
      store.load(zip_path)
      expect(store.concept_count).to eq(2)
    end
  end

  describe "#save_directory" do
    it "writes all entries to a directory" do
      store.load_directory(glossary_dir)

      output = File.join(tmpdir, "output")
      store.save_directory(output)

      expect(File.exist?(File.join(output, "metadata.yaml"))).to be true
      expect(File.exist?(File.join(output, "register.yaml"))).to be true
      expect(File.exist?(File.join(output, "bibliography.yaml"))).to be true
      expect(Dir.glob(File.join(output, "concepts", "*.yaml")).length).to eq(2)
    end
  end

  describe "#save_zip" do
    it "writes all entries to a ZIP archive" do
      store.load_directory(glossary_dir)

      output = File.join(tmpdir, "output.gcr")
      store.save_zip(output)

      expect(File.exist?(output)).to be true
    end
  end

  describe "legacy V3 concept/ + localized_concept/ layout" do
    # Regression: when a V3 dataset uses the legacy split layout
    # (concept/{id}.yaml + localized_concept/{uuid}.yaml), the loader
    # must dispatch to V3::LocalizedConcept — not the base
    # LocalizedConcept — so V3 ConceptData fields (annotations,
    # scoped examples, etc.) parse correctly. Before the fix, the
    # legacy loader unconditionally picked the base class for any
    # version other than "2", silently dropping V3-specific fields.
    let(:v3_concept_yaml) do
      <<~YAML
        ---
        data:
          identifier: "1.1"
          localized_concepts:
            eng: lc-1-1-eng
        status: valid
        schema_version: '3'
        id: c-1-1
      YAML
    end

    let(:v3_l10n_yaml) do
      <<~YAML
        ---
        data:
          definition:
          - content: a concept with annotations
          terms:
          - type: expression
            normative_status: preferred
            designation: annotated term
          notes:
          - content: a note
          examples:
          - content: an example
          annotations:
          - content: editorial annotation about the entry
          language_code: eng
          entry_status: valid
        id: lc-1-1-eng
      YAML
    end

    let(:v3_legacy_dir) do
      dir = File.join(tmpdir, "v3-legacy")
      concept_dir = File.join(dir, "concept")
      lc_dir = File.join(dir, "localized_concept")
      FileUtils.mkdir_p(concept_dir)
      FileUtils.mkdir_p(lc_dir)
      File.write(File.join(concept_dir, "c-1-1.yaml"), v3_concept_yaml,
                 encoding: "utf-8")
      File.write(File.join(lc_dir, "lc-1-1-eng.yaml"), v3_l10n_yaml,
                 encoding: "utf-8")
      dir
    end

    it "dispatches to V3::LocalizedConcept for schema_version 3" do
      store.load(v3_legacy_dir)
      mc = store.concepts.first
      l10n = mc.localization("eng")

      expect(l10n).to be_a(Glossarist::V3::LocalizedConcept)
      expect(l10n.data).to be_a(Glossarist::V3::ConceptData)
    end

    it "preserves V3 ConceptData fields including annotations" do
      store.load(v3_legacy_dir)
      mc = store.concepts.first
      l10n = mc.localization("eng")

      expect(l10n.data.annotations.map(&:content)).to(
        eq(["editorial annotation about the entry"]),
      )
      expect(l10n.data.notes.map(&:content)).to eq(["a note"])
      expect(l10n.data.examples.map(&:content)).to eq(["an example"])
    end
  end

  describe "#concepts" do
    it "returns ManagedConcept instances" do
      store.load_directory(glossary_dir)
      all = store.concepts
      expect(all.length).to eq(2)
      all.each { |mc| expect(mc).to be_a(Glossarist::ManagedConcept) }
    end
  end

  describe "#concept" do
    it "retrieves a concept by UUID" do
      store.load_directory(glossary_dir)
      mc = store.concept("aaa-111")
      expect(mc).not_to be_nil
      expect(mc.uuid).to eq("aaa-111")
    end

    it "returns nil for missing UUID" do
      store.load_directory(glossary_dir)
      expect(store.concept("nonexistent")).to be_nil
    end
  end

  describe "#add_concept / #remove_concept" do
    it "adds a concept" do
      mc = build_test_managed_concept("new-001", "new term")
      store.add_concept(mc)
      expect(store.concept_exists?("new-001")).to be true
    end

    it "removes a concept" do
      store.load_directory(glossary_dir)
      expect(store.concept_exists?("aaa-111")).to be true
      store.remove_concept("aaa-111")
      expect(store.concept_exists?("aaa-111")).to be false
    end
  end

  describe "round-trip" do
    it "directory -> directory preserves all data" do
      store.load_directory(glossary_dir)

      output = File.join(tmpdir, "roundtrip")
      store.save_directory(output)

      reloaded = described_class.new
      reloaded.load_directory(output)

      expect(reloaded.concept_count).to eq(store.concept_count)
      expect(reloaded.metadata.shortname).to eq(store.metadata.shortname)
    end

    it "directory -> ZIP -> directory preserves all data" do
      store.load_directory(glossary_dir)

      zip_path = File.join(tmpdir, "roundtrip.gcr")
      store.save_zip(zip_path)

      reloaded = described_class.new
      reloaded.load_zip(zip_path)

      expect(reloaded.concept_count).to eq(store.concept_count)
    end
  end

  describe "#stats" do
    it "reports package stats" do
      store.load_directory(glossary_dir)
      s = store.stats
      expect(s[:package]).to eq(:gcr)
      expect(s[:metadata]).to be true
    end
  end

  private

  def build_test_managed_concept(uuid, term_text)
    mc = Glossarist::ManagedConcept.new(
      data: Glossarist::ManagedConceptData.new(
        id: uuid,
        status: "valid",
      ),
    )
    mc.uuid = uuid

    l10n = Glossarist::LocalizedConcept.new(
      data: Glossarist::ConceptData.new(
        definition: [Glossarist::DetailedDefinition.new(content: "Test definition")],
        language_code: "eng",
      ),
    )
    designation = Glossarist::Designation::Expression.new(
      designation: term_text,
      normative_status: "preferred",
    )
    l10n.data.terms = [designation]
    mc.add_localization(l10n)

    mc
  end

  def create_test_zip(source_dir, zip_path)
    Zip::File.open(zip_path, create: true) do |zf|
      Dir.glob(File.join(source_dir, "**", "*")).each do |file|
        next unless File.file?(file)

        relative = file.sub(%r{\A#{Regexp.escape(source_dir)}/}, "")
        zf.add(relative, file)
      end
    end
    zip_path
  end
end
