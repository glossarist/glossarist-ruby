# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::ConceptEnricher do
  let(:enricher) { described_class.new }

  def build_managed_concept(termid, localizations)
    mc = Glossarist::ManagedConcept.new(data: { id: termid })
    localizations.each do |lang, data|
      l10n = Glossarist::LocalizedConcept.of_yaml({
                                                    "data" => {
                                                      "language_code" => lang,
                                                      "terms" => [{ "type" => "expression",
                                                                    "designation" => data[:designation] }],
                                                      "definition" => [{ "content" => data[:definition] }],
                                                      "entry_status" => "valid",
                                                    },
                                                  })
      mc.add_localization(l10n)
    end
    mc
  end

  describe "#inject_references" do
    it "injects references per-localization, not across localizations" do
      mc = build_managed_concept("100", {
                                   eng: { designation: "latitude",
                                          definition: "See {{equality, urn:iec:std:iec:60050-102-01-01}}" },
                                   fra: { designation: "latitude",
                                          definition: "Voir {{egalite, 200}}" },
                                 })

      enricher.inject_references([mc])

      eng_refs = mc.localization("eng").data.references
      fra_refs = mc.localization("fra").data.references

      eng_ids = eng_refs.map(&:concept_id)
      fra_ids = fra_refs.map(&:concept_id)

      expect(eng_ids).to contain_exactly("102-01-01")
      expect(fra_ids).to contain_exactly("200")

      expect(eng_ids).not_to include("200")
      expect(fra_ids).not_to include("102-01-01")
    end

    it "preserves existing references" do
      mc = build_managed_concept("100", {
                                   eng: { designation: "test", definition: "See {{other, 200}}" },
                                 })
      existing_ref = Glossarist::ConceptReference.new(
        term: "preexisting", concept_id: "999", source: nil, ref_type: "local",
      )
      mc.localization("eng").data.references = [existing_ref]

      enricher.inject_references([mc])

      refs = mc.localization("eng").data.references
      ids = refs.map(&:concept_id)
      expect(ids).to contain_exactly("999", "200")
    end

    it "does not duplicate references" do
      mc = build_managed_concept("100", {
                                   eng: { designation: "test", definition: "See {{X, 100}} and {{Y, 100}}" },
                                 })

      enricher.inject_references([mc])

      refs = mc.localization("eng").data.references
      expect(refs.length).to eq(1)
    end
  end

  describe "#apply_uri_template" do
    it "sets URI on each concept from template" do
      concepts = [
        build_managed_concept("102-01-01",
                              { eng: { designation: "test",
                                       definition: "def" } }),
        build_managed_concept("102-01-02",
                              { eng: { designation: "test2",
                                       definition: "def2" } }),
      ]

      enricher.apply_uri_template(concepts, "urn:iec:std:iec:60050-{id}")

      expect(concepts[0].data.uri).to eq("urn:iec:std:iec:60050-102-01-01")
      expect(concepts[1].data.uri).to eq("urn:iec:std:iec:60050-102-01-02")
    end
  end
end
