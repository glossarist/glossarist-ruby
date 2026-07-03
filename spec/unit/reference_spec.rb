# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Reference do
  # The protocol guarantees that any reference kind produced by
  # ReferenceExtractor answers cite?/local?/external? without raising,
  # so validation rules can iterate mixed collections via select(&:cite?)
  # and friends without type-checking. Regression for the crash that hit
  # CiteRefIntegrityRule when an AssetReference reached its select block.
  describe "default predicates (false for non-concept references)" do
    let(:subjects) do
      [
        Glossarist::BibliographicReference.new(anchor: "ISO_9000"),
        Glossarist::AssetReference.new(path: "img/x.png"),
        Glossarist::FigureReference.new(entity_id: "fig-1"),
        Glossarist::TableReference.new(entity_id: "tbl-1"),
        Glossarist::FormulaReference.new(entity_id: "fml-1"),
      ]
    end

    it "returns false from cite?" do
      subjects.each { |r| expect(r).not_to be_cite }
    end

    it "returns false from local?" do
      subjects.each { |r| expect(r).not_to be_local }
    end

    it "returns false from external?" do
      subjects.each { |r| expect(r).not_to be_external }
    end
  end

  describe "ConceptReference overrides" do
    it "treats ref_type 'cite' as cite?" do
      ref = Glossarist::ConceptReference.new(
        concept_id: "iso-7301", ref_type: "cite",
      )
      expect(ref).to be_cite
      expect(ref).to be_local
      expect(ref).not_to be_external
    end

    it "treats source-bearing ref as external" do
      ref = Glossarist::ConceptReference.new(
        concept_id: "103-01-01",
        source: "urn:iso:std:iso:iso-10241-1",
        ref_type: "urn",
      )
      expect(ref).to be_external
      expect(ref).not_to be_local
      expect(ref).not_to be_cite
    end

    it "treats ref_type 'local' as local but not cite" do
      ref = Glossarist::ConceptReference.new(
        concept_id: "103-01-01", ref_type: "local",
      )
      expect(ref).to be_local
      expect(ref).not_to be_cite
    end
  end

  describe "mixed-collection iteration (regression for image:: crash)" do
    it "allows select(&:cite?) over ReferenceExtractor output without raising" do
      mc = Glossarist::ManagedConcept.new(data: { id: "1" })
      data = {
        "language_code" => "eng",
        "terms" => [{ "type" => "expression",
                      "designation" => "test", "normative_status" => "preferred" }],
        "definition" => [{ "content" => "See image::diagram.png[] and {{cite:missing}}." }],
        "entry_status" => "valid",
      }
      l10n = Glossarist::LocalizedConcept.of_yaml({ "data" => data })
      mc.add_localization(l10n)

      refs = Glossarist::ReferenceExtractor.new.extract_from_managed_concept(mc)
      expect(refs.map { |r| r.class.name }).to include(
        "Glossarist::ConceptReference", "Glossarist::AssetReference"
      )

      cite_refs = refs.select(&:cite?)
      expect(cite_refs.map(&:concept_id)).to eq(["missing"])
    end
  end
end
