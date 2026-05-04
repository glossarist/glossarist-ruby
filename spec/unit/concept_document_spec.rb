# frozen_string_literal: true

RSpec.describe Glossarist::ConceptDocument do
  let(:v2_yaml) do
    <<~YAMLS
      ---
      data:
        identifier: '2119'
        localized_concepts:
          eng: da24b782-1551-5128-a043-ba6135a25acf
        sources:
        - origin:
            ref: ISO 1087-1:2000
            locality:
              type: clause
              reference_from: 3.2.9
            link: https://www.iso.org/standard/20057.html
          type: authoritative
      id: 003a8c14-f962-5688-aefe-38c736bebfb2
      status: valid

      ---
      data:
        dates:
        - date: '2017-11-15T00:00:00+00:00'
          type: accepted
        definition:
        - content: constituent part of a postal address
        examples:
        - content: Locality, postcode, thoroughfare, premises identifier
        id: '2119'
        notes:
        - content: The components of postal addresses are defined in 6.2, 6.3 and 6.4.
        - content: A postal address component may be, but is not limited to, an element,
            a construct or a segment.
        release: '5'
        sources:
        - origin:
            ref: ISO 19160-4:2017
            locality:
              type: clause
              reference_from: '3.12'
            link: https://www.iso.org/standard/64242.html
          type: authoritative
        terms:
        - type: expression
          normative_status: admitted
          designation: component
        - type: expression
          designation: postal address component
        domain: postal address
        language_code: eng
      date_accepted: '2017-11-15T00:00:00+00:00'
      id: da24b782-1551-5128-a043-ba6135a25acf
    YAMLS
  end

  describe "parsing heterogeneous YAML stream" do
    subject(:doc) { described_class.from_yamls(v2_yaml) }

    it "parses document 0 as ManagedConcept" do
      expect(doc.concept).to be_a(Glossarist::ManagedConcept)
    end

    it "parses concept identifier" do
      expect(doc.concept.identifier).to eq("003a8c14-f962-5688-aefe-38c736bebfb2")
    end

    it "parses concept data" do
      expect(doc.concept.data.id).to eq("2119")
      expect(doc.concept.data.localized_concepts).to eq(
        "eng" => "da24b782-1551-5128-a043-ba6135a25acf",
      )
    end

    it "parses concept sources" do
      source = doc.concept.data.sources.first
      expect(source.origin.text).to eq("ISO 1087-1:2000")
      expect(source.type).to eq("authoritative")
    end

    it "parses docs 1+ as LocalizedConcept collection" do
      expect(doc.localizations).to be_an(Array)
      expect(doc.localizations.size).to eq(1)
    end

    it "parses localized concept fields" do
      lc = doc.localizations.first
      expect(lc).to be_a(Glossarist::LocalizedConcept)
      expect(lc.language_code).to eq("eng")
    end

    it "parses localized concept definition" do
      lc = doc.localizations.first
      expect(lc.data.definition.first.content).to eq("constituent part of a postal address")
    end

    it "parses localized concept terms" do
      lc = doc.localizations.first
      expect(lc.data.terms.size).to eq(2)
      expect(lc.data.terms.first.designation).to eq("component")
    end

    it "parses localized concept notes" do
      lc = doc.localizations.first
      expect(lc.data.notes.size).to eq(2)
    end
  end

  describe "round-trip serialization" do
    subject(:doc) { described_class.from_yamls(v2_yaml) }

    it "produces a YAML stream with 2 documents" do
      output = doc.to_yamls
      doc2 = described_class.from_yamls(output)
      expect(doc2.concept).to be_a(Glossarist::ManagedConcept)
      expect(doc2.localizations.length).to eq(1)
    end

    it "round-trips concept data" do
      output = doc.to_yamls
      doc2 = described_class.from_yamls(output)

      expect(doc2.concept.data.id).to eq("2119")
      expect(doc2.concept.data.localized_concepts).to eq(
        "eng" => "da24b782-1551-5128-a043-ba6135a25acf",
      )
    end

    it "round-trips localized concept data" do
      output = doc.to_yamls
      doc2 = described_class.from_yamls(output)

      lc = doc2.localizations.first
      expect(lc.language_code).to eq("eng")
      expect(lc.data.definition.first.content).to eq("constituent part of a postal address")
      expect(lc.data.terms.first.designation).to eq("component")
    end
  end

  describe "with multiple localizations" do
    let(:multi_l10n_yaml) do
      <<~YAMLS
        ---
        data:
          identifier: '102-01-01'
          localized_concepts:
            eng: eng-uuid-001
            fra: fra-uuid-001
        id: mc-uuid-001
        status: valid

        ---
        data:
          definition:
          - content: English definition text
          terms:
          - type: expression
            designation: English term
          language_code: eng
        id: eng-uuid-001

        ---
        data:
          definition:
          - content: French definition text
          terms:
          - type: expression
            designation: French term
          language_code: fra
        id: fra-uuid-001
      YAMLS
    end

    it "parses 1 concept + 2 localizations" do
      doc = described_class.from_yamls(multi_l10n_yaml)
      expect(doc.localizations.size).to eq(2)
      expect(doc.localizations[0].language_code).to eq("eng")
      expect(doc.localizations[1].language_code).to eq("fra")
    end

    it "round-trips 3 documents" do
      doc = described_class.from_yamls(multi_l10n_yaml)
      output = doc.to_yamls
      doc2 = described_class.from_yamls(output)

      expect(doc2.localizations.size).to eq(2)
      expect(doc2.localizations[0].data.terms.first.designation).to eq("English term")
      expect(doc2.localizations[1].data.terms.first.designation).to eq("French term")
    end
  end

  describe ".from_managed_concept" do
    let(:managed_concept) do
      mc = Glossarist::ManagedConcept.new(
        data: {
          id: "2119",
          localized_concepts: { "eng" => "da24b782-1551-5128-a043-ba6135a25acf" },
        },
        status: "valid",
      )
      l10n = Glossarist::LocalizedConcept.of_yaml({
                                                    "data" => {
                                                      "language_code" => "eng",
                                                      "terms" => [{
                                                        "designation" => "component", "type" => "expression"
                                                      }],
                                                      "definition" => [{ "content" => "constituent part of a postal address" }],
                                                    },
                                                  })
      mc.add_localization(l10n)
      mc
    end

    it "builds a ConceptDocument from a ManagedConcept" do
      doc = described_class.from_managed_concept(managed_concept)

      expect(doc.concept).to be_a(Glossarist::ManagedConcept)
      expect(doc.localizations).to be_an(Array)
      expect(doc.localizations.size).to eq(1)
    end

    it "preserves concept data" do
      doc = described_class.from_managed_concept(managed_concept)
      expect(doc.concept.data.id).to eq("2119")
      expect(doc.localizations.first.language_code).to eq("eng")
    end
  end

  describe "#to_managed_concept" do
    let(:doc) { described_class.from_yamls(v2_yaml) }

    it "returns a ManagedConcept" do
      mc = doc.to_managed_concept
      expect(mc).to be_a(Glossarist::ManagedConcept)
    end

    it "preserves concept data" do
      mc = doc.to_managed_concept
      expect(mc.data.id).to eq("2119")
      expect(mc.status).to eq("valid")
    end

    it "attaches localizations" do
      mc = doc.to_managed_concept
      expect(mc.localization("eng")).to be_a(Glossarist::LocalizedConcept)
      expect(mc.localization("eng").data.definition.first.content).to eq(
        "constituent part of a postal address",
      )
    end
  end

  describe "full round-trip: ManagedConcept → ConceptDocument → YAML → ConceptDocument → ManagedConcept" do
    let(:original_mc) do
      mc = Glossarist::ManagedConcept.new(
        data: {
          id: "3.5.8.8",
          localized_concepts: { "eng" => "fbe1444a-7c11-555e-bb1b-680a4e6f2502" },
        },
        status: "valid",
      )
      l10n = Glossarist::LocalizedConcept.of_yaml({
                                                    "data" => {
                                                      "language_code" => "eng",
                                                      "terms" => [{ "designation" => "membership-based",
                                                                    "type" => "expression" }],
                                                      "definition" => [{ "content" => "characteristic of a financial model" }],
                                                    },
                                                  })
      mc.add_localization(l10n)
      mc
    end

    it "round-trips through ConceptDocument" do
      doc = described_class.from_managed_concept(original_mc)
      yaml_output = doc.to_yamls

      doc2 = described_class.from_yamls(yaml_output)
      restored_mc = doc2.to_managed_concept

      expect(restored_mc.data.id).to eq("3.5.8.8")
      expect(restored_mc.status).to eq("valid")
      expect(restored_mc.localization("eng").data.terms.first.designation).to eq("membership-based")
    end
  end
end
