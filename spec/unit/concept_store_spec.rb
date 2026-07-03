# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Glossarist::ConceptStore do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  def create_glossary(dir, concepts_data)
    concepts_dir = File.join(dir, "concepts")
    FileUtils.mkdir_p(concepts_dir)

    concepts_data.each do |concept|
      filename = File.join(concepts_dir, "#{concept[:uuid]}.yaml")
      File.write(filename, concept[:yaml], encoding: "utf-8")
    end
  end

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

  let(:glossary_dir) do
    dir = tmpdir
    create_glossary(dir, [
                      { uuid: "aaa-111", yaml: concept_a_yaml },
                      { uuid: "bbb-222", yaml: concept_b_yaml },
                    ])
    dir
  end

  describe "#load_glossary" do
    it "loads all concepts from a GCR v3 directory" do
      store = described_class.new
      docs = store.load_glossary(glossary_dir)

      expect(docs.length).to eq(2)
      expect(store.count).to eq(2)
    end

    it "loads concepts through lutaml-store" do
      store = described_class.new
      store.load_glossary(glossary_dir)

      expect(store.db).to be_a(Lutaml::Store::DatabaseStore)
      expect(store.count).to eq(2)
    end
  end

  describe "#fetch" do
    it "retrieves a concept by UUID" do
      store = described_class.new
      store.load_glossary(glossary_dir)

      concept = store.fetch("aaa-111")
      expect(concept).not_to be_nil
      expect(concept.uuid).to eq("aaa-111")
      expect(concept.identifier).to eq("aaa-111")
      expect(concept.data.id).to eq("3.1.1")
    end

    it "returns nil for non-existent UUID" do
      store = described_class.new
      store.load_glossary(glossary_dir)

      expect(store.fetch("nonexistent")).to be_nil
    end

    it "preserves concept localizations" do
      store = described_class.new
      store.load_glossary(glossary_dir)

      concept = store.fetch("bbb-222")
      expect(concept.localizations.keys).to contain_exactly("eng", "fra")

      eng_l10n = concept.localization("eng")
      expect(eng_l10n.data.definition.first.content).to eq("Test definition B")
      expect(eng_l10n.terms.first.designation).to eq("term beta")

      fra_l10n = concept.localization("fra")
      expect(fra_l10n.terms.first.designation).to eq("terme beta")
    end
  end

  describe "#concepts" do
    it "returns all concepts" do
      store = described_class.new
      store.load_glossary(glossary_dir)

      all = store.concepts
      expect(all.length).to eq(2)
      expect(all.map(&:uuid).sort).to eq(%w[aaa-111 bbb-222])
    end
  end

  describe "#count" do
    it "returns zero for empty store" do
      store = described_class.new
      expect(store.count).to eq(0)
    end

    it "returns the number of loaded concepts" do
      store = described_class.new
      store.load_glossary(glossary_dir)
      expect(store.count).to eq(2)
    end
  end

  describe "#exists?" do
    it "returns true for existing concept" do
      store = described_class.new
      store.load_glossary(glossary_dir)

      expect(store.exists?("aaa-111")).to be true
      expect(store.exists?("bbb-222")).to be true
    end

    it "returns false for non-existent concept" do
      store = described_class.new
      store.load_glossary(glossary_dir)

      expect(store.exists?("nonexistent")).to be false
    end
  end

  describe "#clear" do
    it "removes all concepts" do
      store = described_class.new
      store.load_glossary(glossary_dir)

      expect(store.count).to eq(2)
      store.clear
      expect(store.count).to eq(0)
    end
  end

  describe "with real glossary fixtures" do
    it "loads the isotc204 glossary" do
      tc204_path = File.expand_path("../../geolexica/isotc204-glossary",
                                    __dir__)
      skip "isotc204 glossary not available" unless Dir.exist?(tc204_path)

      store = described_class.new
      store.load_glossary(tc204_path)

      expect(store.count).to eq(319)

      concept = store.concepts.first
      expect(concept).to be_a(Glossarist::ManagedConcept)
      expect(concept.uuid).not_to be_nil
      expect(concept.data.id).not_to be_nil
      expect(concept.localizations).not_to be_empty
    end
  end

  describe "filename ≠ UUID (files named by clause identifier)" do
    # Regression: when files are named by clause identifier (e.g. 3.1.1.1.yaml)
    # rather than by UUID, the lutaml-store record key is the clause. The
    # ConceptDocumentSerializer used to unconditionally overwrite
    # concept.uuid with doc.id (the record key), losing the real UUID that
    # was correctly parsed from the YAML stream.
    #
    # The fix: only fall back to doc.id when the YAML stream did not
    # provide a UUID — see ConceptDocument#ensure_concept_uuid!.
    let(:yaml_with_real_uuid) do
      <<~YAML
        ---
        data:
          identifier: "3.1.1.1"
          localized_concepts:
            eng: l10n-uuid-eng
        status: valid
        schema_version: '3'
        id: 11111111-2222-3333-4444-555555555555
        ---
        data:
          definition:
          - content: definition text
          terms:
          - type: expression
            normative_status: preferred
            designation: term
          language_code: eng
          entry_status: valid
        id: l10n-uuid-eng
      YAML
    end

    let(:clause_named_dir) do
      dir = tmpdir
      concepts_dir = File.join(dir, "concepts")
      FileUtils.mkdir_p(concepts_dir)
      File.write(File.join(concepts_dir, "3.1.1.1.yaml"), yaml_with_real_uuid,
                 encoding: "utf-8")
      dir
    end

    it "preserves the YAML-provided UUID when filename differs" do
      store = described_class.new
      store.load_glossary(clause_named_dir)

      concept = store.concepts.first
      expect(concept.data.id).to eq("3.1.1.1")
      expect(concept.uuid).to eq("11111111-2222-3333-4444-555555555555")
    end
  end
end
