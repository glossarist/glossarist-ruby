# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/glossarist/sts"

RSpec.describe Glossarist::Sts::TermMapper do
  subject { described_class.new }

  describe "#map" do
    context "with a simple extracted term" do
      let(:extracted_term) do
        Glossarist::Sts::ExtractedTerm.new(
          id: "term_3.1",
          label: "3.1",
          source_ref: "ISO 12345:2021",
          lang_sets: [
            Glossarist::Sts::ExtractedLangSet.new(
              language_code: "eng",
              definition_text: "a test definition",
              note_texts: ["a note"],
              example_texts: ["an example"],
              source_texts: ["ISO 12345:2021, 3.1"],
              domain: "robotics",
              designations: [
                Glossarist::Sts::ExtractedDesignation.new(
                  term: "test robot",
                  type: "expression",
                  normative_status: "preferred",
                  part_of_speech: "noun",
                ),
              ],
            ),
          ],
        )
      end

      let(:concept) { subject.map(extracted_term) }

      it "creates a ManagedConcept" do
        expect(concept).to be_a(Glossarist::ManagedConcept)
      end

      it "uses label as concept ID" do
        expect(concept.data.id).to eq("3.1")
      end

      it "creates a localization" do
        expect(concept.localization("eng")).to be_a(Glossarist::LocalizedConcept)
      end

      it "maps designation" do
        l10n = concept.localization("eng")
        expect(l10n.data.terms.length).to eq(1)
        term = l10n.data.terms.first
        expect(term.designation).to eq("test robot")
        expect(term.normative_status).to eq("preferred")
      end

      it "maps definition" do
        l10n = concept.localization("eng")
        expect(l10n.data.definition.count).to eq(1)
        expect(l10n.data.definition.first.content).to eq("a test definition")
      end

      it "maps notes" do
        l10n = concept.localization("eng")
        expect(l10n.data.notes.count).to eq(1)
        expect(l10n.data.notes.first.content).to eq("a note")
      end

      it "maps examples" do
        l10n = concept.localization("eng")
        expect(l10n.data.examples.count).to eq(1)
        expect(l10n.data.examples.first.content).to eq("an example")
      end

      it "maps domain" do
        l10n = concept.localization("eng")
        expect(l10n.data.domain).to eq("robotics")
      end

      it "creates authoritative source from source_ref" do
        l10n = concept.localization("eng")
        auth_sources = l10n.data.sources.select do |s|
          s.type == "authoritative"
        end
        expect(auth_sources.length).to be >= 1
        first_source = auth_sources.first
        expect(first_source.origin.text).to eq("ISO 12345:2021")
      end

      it "sets entry_status to valid" do
        l10n = concept.localization("eng")
        expect(l10n.data.entry_status).to eq("valid")
      end
    end

    context "with multi-lang extracted term" do
      let(:extracted_term) do
        Glossarist::Sts::ExtractedTerm.new(
          id: "term_1.1",
          label: "1.1",
          source_ref: "ISO 99999:2021",
          lang_sets: [
            Glossarist::Sts::ExtractedLangSet.new(
              language_code: "eng",
              definition_text: "a mechanical device",
              note_texts: [],
              example_texts: [],
              source_texts: [],
              domain: "engineering",
              designations: [
                Glossarist::Sts::ExtractedDesignation.new(
                  term: "machine",
                  type: "expression",
                  normative_status: "preferred",
                  part_of_speech: "noun",
                ),
              ],
            ),
            Glossarist::Sts::ExtractedLangSet.new(
              language_code: "fra",
              definition_text: "un dispositif mecanique",
              note_texts: [],
              example_texts: [],
              source_texts: [],
              domain: "ingenierie",
              designations: [
                Glossarist::Sts::ExtractedDesignation.new(
                  term: "machine",
                  type: "expression",
                  normative_status: "preferred",
                  part_of_speech: "noun",
                ),
              ],
            ),
          ],
        )
      end

      let(:concept) { subject.map(extracted_term) }

      it "creates localizations for both languages" do
        expect(concept.localization("eng")).not_to be_nil
        expect(concept.localization("fra")).not_to be_nil
      end

      it "maps French definition correctly" do
        l10n = concept.localization("fra")
        expect(l10n.data.definition.first.content).to eq("un dispositif mecanique")
      end

      it "maps localized concepts in managed concept data" do
        expect(concept.data.localized_concepts).to include("eng", "fra")
      end
    end

    context "with abbreviation designation" do
      let(:extracted_term) do
        Glossarist::Sts::ExtractedTerm.new(
          id: "term_1.2",
          label: "1.2",
          source_ref: "ISO 99999:2021",
          lang_sets: [
            Glossarist::Sts::ExtractedLangSet.new(
              language_code: "eng",
              definition_text: "a shortened form",
              note_texts: [],
              example_texts: [],
              source_texts: [],
              domain: nil,
              designations: [
                Glossarist::Sts::ExtractedDesignation.new(
                  term: "AE",
                  type: "abbreviation",
                  normative_status: "admitted",
                  part_of_speech: nil,
                  abbreviation_type: "acronym",
                ),
              ],
            ),
          ],
        )
      end

      let(:concept) { subject.map(extracted_term) }

      it "creates an abbreviation designation" do
        l10n = concept.localization("eng")
        term = l10n.data.terms.first
        expect(term).to be_a(Glossarist::Designation::Abbreviation)
        expect(term.designation).to eq("AE")
        expect(term.normative_status).to eq("admitted")
      end
    end

    context "with symbol designation" do
      let(:extracted_term) do
        Glossarist::Sts::ExtractedTerm.new(
          id: "term_4.1",
          label: "4.1",
          source_ref: "ISO 11111:2021",
          lang_sets: [
            Glossarist::Sts::ExtractedLangSet.new(
              language_code: "eng",
              definition_text: "a mathematical symbol",
              note_texts: [],
              example_texts: [],
              source_texts: [],
              domain: "mathematics",
              designations: [
                Glossarist::Sts::ExtractedDesignation.new(
                  term: "v",
                  type: "symbol",
                  normative_status: "admitted",
                ),
              ],
            ),
          ],
        )
      end

      it "creates a symbol designation" do
        concept = subject.map(extracted_term)
        l10n = concept.localization("eng")
        term = l10n.data.terms.first
        expect(term).to be_a(Glossarist::Designation::Symbol)
        expect(term.designation).to eq("v")
      end
    end

    context "with nil source_ref" do
      let(:extracted_term) do
        Glossarist::Sts::ExtractedTerm.new(
          id: "term_5.1",
          label: "5.1",
          source_ref: nil,
          lang_sets: [
            Glossarist::Sts::ExtractedLangSet.new(
              language_code: "eng",
              definition_text: "a concept with no source ref",
              note_texts: [],
              example_texts: [],
              source_texts: ["Some external source"],
              domain: nil,
              designations: [
                Glossarist::Sts::ExtractedDesignation.new(
                  term: "orphan term",
                  type: "expression",
                  normative_status: "preferred",
                ),
              ],
            ),
          ],
        )
      end

      it "only includes lang-set sources when source_ref is nil" do
        concept = subject.map(extracted_term)
        l10n = concept.localization("eng")
        expect(l10n.data.sources.count).to eq(1)
        expect(l10n.data.sources.first.origin.text).to eq("Some external source")
      end
    end

    context "with no label (falls back to termEntry id)" do
      let(:extracted_term) do
        Glossarist::Sts::ExtractedTerm.new(
          id: "term_custom",
          label: nil,
          source_ref: nil,
          lang_sets: [
            Glossarist::Sts::ExtractedLangSet.new(
              language_code: "eng",
              definition_text: "def",
              note_texts: [],
              example_texts: [],
              source_texts: [],
              domain: nil,
              designations: [
                Glossarist::Sts::ExtractedDesignation.new(
                  term: "custom term",
                  type: "expression",
                ),
              ],
            ),
          ],
        )
      end

      it "uses termEntry ID as concept ID" do
        concept = subject.map(extracted_term)
        expect(concept.data.id).to eq("term_custom")
      end
    end
  end
end
