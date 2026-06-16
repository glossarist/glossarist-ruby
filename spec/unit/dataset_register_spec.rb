# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::DatasetRegister do
  let(:sample_yaml) do
    <<~YAML
      ---
      schema_type: glossarist
      schema_version: '3'
      id: test-dataset
      ref: "Test Publication"
      year: 2024
      urn: "urn:test:dataset:2024"
      urnAliases:
        - "urn:test:dataset:2024*"
      status: current
      supersedes: test-dataset-2020
      owner: TestOrg
      sourceRepo: https://example.com/repo
      tags:
        - test
        - vocabulary
      languages:
        - eng
        - fra
      languageOrder:
        - eng
        - fra
      ordering: systematic
      sections:
        - id: "1"
          names:
            eng: "General"
            fra: "Général"
        - id: "2"
          names:
            eng: "Specific"
          children:
            - id: "2.1"
              names:
                eng: "Sub-section"
      description:
        eng: "A test dataset"
        fra: "Un jeu de données test"
      about:
        eng: about-eng.md
        fra: about-fra.md
    YAML
  end

  subject(:register) { described_class.from_yaml(sample_yaml) }

  describe "parsing" do
    it "reads identity fields" do
      expect(register.schema_type).to eq("glossarist")
      expect(register.schema_version).to eq("3")
      expect(register.id).to eq("test-dataset")
      expect(register.ref).to eq("Test Publication")
      expect(register.year).to eq(2024)
    end

    it "reads URN fields" do
      expect(register.urn).to eq("urn:test:dataset:2024")
      expect(register.urn_aliases).to eq(["urn:test:dataset:2024*"])
    end

    it "reads status and relationships" do
      expect(register.status).to eq("current")
      expect(register.supersedes).to eq("test-dataset-2020")
    end

    it "reads provenance" do
      expect(register.owner).to eq("TestOrg")
      expect(register.source_repo).to eq("https://example.com/repo")
      expect(register.tags).to eq(%w[test vocabulary])
    end

    it "reads language configuration" do
      expect(register.languages).to eq(%w[eng fra])
      expect(register.language_order).to eq(%w[eng fra])
      expect(register.ordering).to eq("systematic")
    end

    it "reads sections with hierarchy" do
      expect(register.sections.length).to eq(2)
      expect(register.sections[0].id).to eq("1")
      expect(register.sections[0].name("eng")).to eq("General")
      expect(register.sections[0].name("fra")).to eq("Général")
    end

    it "reads hierarchical children" do
      section2 = register.sections[1]
      expect(section2.id).to eq("2")
      expect(section2.children.length).to eq(1)
      expect(section2.children[0].id).to eq("2.1")
      expect(section2.children[0].name("eng")).to eq("Sub-section")
    end

    it "reads localized metadata" do
      expect(register.description).to eq({ "eng" => "A test dataset",
                                           "fra" => "Un jeu de données test" })
      expect(register.about).to eq({ "eng" => "about-eng.md",
                                     "fra" => "about-fra.md" })
    end
  end

  describe "section_by_id" do
    it "finds top-level section" do
      section = register.section_by_id("1")
      expect(section).not_to be_nil
      expect(section.name("eng")).to eq("General")
    end

    it "finds nested section" do
      section = register.section_by_id("2.1")
      expect(section).not_to be_nil
      expect(section.name("eng")).to eq("Sub-section")
    end

    it "returns nil for unknown id" do
      expect(register.section_by_id("999")).to be_nil
    end
  end

  describe "YAML round-trip" do
    it "preserves all fields through serialization" do
      yaml = register.to_yaml
      parsed = described_class.from_yaml(yaml)

      expect(parsed.id).to eq("test-dataset")
      expect(parsed.urn).to eq("urn:test:dataset:2024")
      expect(parsed.sections.length).to eq(2)
      expect(parsed.sections[1].children.length).to eq(1)
      expect(parsed.ordering).to eq("systematic")
      expect(parsed.supersedes).to eq("test-dataset-2020")
    end
  end

  describe "section cascading membership" do
    let(:hierarchical_yaml) do
      <<~YAML
        ---
        schema_type: glossarist
        schema_version: '3'
        id: hierarchical
        urn: "urn:test:hierarchical"
        sections:
          - id: "1"
            names: { eng: "General" }
          - id: "3"
            names: { eng: "Geometric" }
            children:
              - id: "3.1"
                names: { eng: "Points" }
                children:
                  - id: "3.1.1"
                    names: { eng: "Pixels" }
      YAML
    end

    let(:reg) { described_class.from_yaml(hierarchical_yaml) }

    it "returns ancestor chain for deeply nested section" do
      expect(reg.section_ancestor_ids("3.1.1")).to eq(%w[3.1 3])
    end

    it "returns immediate parent for child of top-level" do
      expect(reg.section_ancestor_ids("3.1")).to eq(["3"])
    end

    it "returns empty for top-level section" do
      expect(reg.section_ancestor_ids("1")).to eq([])
    end

    it "returns empty for non-existent section" do
      expect(reg.section_ancestor_ids("999")).to eq([])
    end

    it "resolves concept section IDs with cascading ancestors" do
      concept = Glossarist::ManagedConcept.new(
        data: {
          id: "3.1.1",
          domains: [{ concept_id: "3.1.1", ref_type: "section" }],
        },
      )
      expect(reg.concept_section_ids(concept)).to eq(%w[3.1.1 3.1 3])
    end

    it "derives section from term-ID-prefix when no explicit domains" do
      concept = Glossarist::ManagedConcept.new(data: { id: "3-01-01" })
      # No explicit domain → derive from "3" prefix
      expect(reg.concept_section_ids(concept)).to eq(["3"])
    end

    it "returns empty when concept has no domains and no matching prefix" do
      concept = Glossarist::ManagedConcept.new(data: { id: "999" })
      expect(reg.concept_section_ids(concept)).to eq([])
    end
  end

  describe "from_file" do
    it "loads from an actual register.yaml file" do
      path = File.expand_path("../../fixtures/viml-2022-register.yaml", __dir__)
      skip("fixture not found") unless File.exist?(path)

      reg = described_class.from_file(path)
      expect(reg.id).to eq("viml-2022")
      expect(reg.sections.length).to be > 0
    end
  end
end
