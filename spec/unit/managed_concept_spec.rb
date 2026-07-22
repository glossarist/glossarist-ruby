# frozen_string_literal: true

RSpec.describe Glossarist::ManagedConcept do
  subject { described_class.from_yaml(concept.to_yaml) }

  let(:concept) do
    {
      "data" => {
        "id" => "123",
        "localized_concepts" => {
          "ara" => "uuid",
        },
        "localizations" => [localized_concept],
        "domains" => [
          { "concept_id" => "foo", "ref_type" => "domain" },
          { "concept_id" => "bar", "ref_type" => "domain" },
        ],
      },
      "status" => "valid",
    }
  end

  let(:localized_concept) do
    {
      "data" => {
        "language_code" => "ara",
        "terms" => [
          {
            "designation" => "Arabic Designation",
            "type" => "expression",
          },
        ],
        "dates" => [
          {
            "type" => "accepted",
            "date" => "2020-01-01",
          },
        ],
      },
    }
  end

  describe "#id" do
    it "sets the id of the concept" do
      expect { subject.id = "1234" }
        .to change { subject.id }.to("1234")
    end
  end

  describe "#status" do
    it "sets the status of the concept" do
      expect { subject.status = "superseded" }
        .to change { subject.status }.from("valid").to("superseded")
    end
  end

  describe "#related=" do
    it "sets the related concepts" do
      subject.related = [Glossarist::RelatedConcept.of_yaml({
                                                              "type" => "supersedes", "content" => { "eng" => "Example content" }
                                                            })]

      expect(subject.related.first.type).to eq("supersedes")
      expect(subject.related.first.content).to eq("eng" => "Example content")
    end

    it "generates dynamic *_concepts methods for all relationship types" do
      subject.related = [
        Glossarist::RelatedConcept.new(type: "broader_generic",
                                       content: { "eng" => "Vehicle" }),
        Glossarist::RelatedConcept.new(type: "broader_partitive",
                                       content: { "eng" => "Engine" }),
        Glossarist::RelatedConcept.new(type: "narrower", content: { "eng" => "Truck" }),
      ]

      expect(subject.broader_generic_concepts.map(&:content)).to eq([{ "eng" => "Vehicle" }])
      expect(subject.broader_partitive_concepts.map(&:content)).to eq([{ "eng" => "Engine" }])
      expect(subject.narrower_concepts.map(&:content)).to eq([{ "eng" => "Truck" }])
      expect(subject.broader_concepts).to be_empty
    end
  end

  describe "#dates=" do
    it "sets the dates" do
      subject.dates = [Glossarist::ConceptDate.of_yaml({ "type" => "accepted",
                                                         "date" => "2020-01-01" })]

      expect(subject.dates.first.type).to eq("accepted")
      expect(subject.dates.first.date).to eq(Date.parse("2020-01-01"))
    end
  end

  describe "#domains" do
    it "sets domain references as ConceptReference objects" do
      ref = Glossarist::ConceptReference.new(concept_id: "103",
                                             ref_type: "domain")
      expect { subject.data.domains = [ref] }
        .to change { subject.data.domains }.to([ref])
      expect(subject.data.domains.first).to be_a(Glossarist::ConceptReference)
      expect(subject.data.domains.first.concept_id).to eq("103")
    end

    it "migrates legacy groups strings to domain references" do
      mc = described_class.from_yaml({
        "data" => {
          "id" => "123",
          "groups" => ["foo", "bar"],
          "localized_concepts" => { "eng" => "uuid" },
        },
      }.to_yaml)
      expect(mc.data.domains.length).to eq(2)
      expect(mc.data.domains.first.concept_id).to eq("foo")
      expect(mc.data.domains.first.ref_type).to eq("domain")
    end
  end

  describe "#sources" do
    let(:source) do
      {
        "status" => "identical",
        "origin" => { "ref" => { "source" => "Concept level source" } },
      }
    end

    it "sets the sources list at the concept level" do
      expect(subject.sources).to be_nil

      subject.sources = [Glossarist::ConceptSource.from_yaml(source.to_yaml)]

      expect(subject.sources.first.status).to eq(source["status"])
      expect(subject.sources.first.origin.ref.source).to eq("Concept level source")
    end
  end

  describe "#to_yaml" do
    let(:expected_concept_hash) do
      {
        "data" => {
          "identifier" => "123",
          "localized_concepts" => {
            "ara" => "uuid",
          },
          "domains" => [
            { "concept_id" => "foo", "ref_type" => "domain" },
            { "concept_id" => "bar", "ref_type" => "domain" },
          ],
        },
        "id" => "ebb21fa2-87a9-5895-84f6-37f022f4f550",
        "status" => "valid",
      }
    end

    it "dumps concept definition to a yaml" do
      retval = described_class.from_yaml(subject.to_yaml)

      expect(retval).to be_kind_of(Glossarist::ManagedConcept)
      expect(retval.data.localized_concepts).to eq(expected_concept_hash["data"]["localized_concepts"])
      expect(retval.status).to eq("valid")
    end
  end

  describe "#localized_concepts=" do
    let(:localized_concepts) do
      [
        {
          "data" => {
            "language_code" => "eng",
            "definition" => [
              {
                "content" => "this is very important",
              },
            ],
            "entry_status" => "valid",
          },
        },
      ]
    end

    it "accepts a hash" do
      expect { subject.localized_concepts = localized_concepts }
        .not_to raise_error
    end

    it "accepts a hash of attributes and create a concept" do
      subject.localized_concepts = localized_concepts

      expect(subject.data.localized_concepts).to be_a(Hash)
    end

    it "should have same uuid in localized concept hash and the localized concept" do
      subject.localized_concepts = localized_concepts

      expect(subject.localization("eng").uuid).to eq(subject.localized_concepts["eng"])
    end
  end

  describe "#add_localization" do
    let(:localizations) do
      [
        Glossarist::LocalizedConcept.of_yaml({
                                               "data" => {
                                                 "id" => "123",
                                                 "language_code" => "eng",
                                                 "definition" => [
                                                   {
                                                     "content" => "this is very important",
                                                   },
                                                 ],
                                                 "entry_status" => "valid",
                                               },
                                             }),
      ]
    end

    it "accepts a hash" do
      expect { subject.data.localizations = { "eng" => localizations.first } }
        .not_to raise_error
    end

    it "accepts a hash of attributes and create a concept" do
      localizations.each do |localized_concept|
        subject.add_localization(localized_concept)
      end

      expect(subject.data.localizations).to be_a(Glossarist::Collections::LocalizationCollection)
      expect(subject.data.localizations["eng"]).to be_a(Glossarist::LocalizedConcept)
      expect(subject.data.localizations["eng"].data.definition.first.content).to eq("this is very important")
      expect(subject.data.localizations["eng"].entry_status).to eq("valid")
    end
  end

  describe "#default_designation" do
    it "returns first English designation when available" do
      localized_concept = Glossarist::LocalizedConcept.of_yaml(
        "data" => {
          "language_code" => "eng",
          "terms" => [
            {
              "designation" => "English Designation",
              "type" => "expression",
            },
          ],
        },
      )
      object = described_class.of_yaml("data" => { id: "123" })
      object.add_l10n(localized_concept)

      expect(object.default_designation).to eq("English Designation")
    end

    it "retunrs any designation when English localization is missing" do
      expect(subject.default_designation).to eq("Arabic Designation")
    end
  end

  describe "#find_source_by_id" do
    it "returns nil when no source has the id" do
      expect(subject.find_source_by_id("anything")).to be_nil
    end

    it "returns nil for nil or empty id" do
      expect(subject.find_source_by_id(nil)).to be_nil
      expect(subject.find_source_by_id("")).to be_nil
      expect(subject.find_source_by_id("  ")).to be_nil
    end

    it "finds a concept-level source by id" do
      source = Glossarist::ConceptSource.new(
        id: "iso-7301-3-2",
        type: "authoritative",
        origin: Glossarist::Citation.new(
          ref: Glossarist::Citation::Ref.new(source: "ISO", id: "7301"),
        ),
      )
      subject.sources = [source]
      expect(subject.find_source_by_id("iso-7301-3-2")).to eq(source)
    end

    it "finds a localization-level source by id" do
      source = Glossarist::ConceptSource.new(
        id: "smith-2020",
        type: "lineage",
        origin: Glossarist::Citation.new(
          ref: Glossarist::Citation::Ref.new(source: "DOI", id: "10.1234/abc"),
        ),
      )
      l10n = Glossarist::LocalizedConcept.of_yaml(
        "data" => {
          "language_code" => "eng",
          "terms" => [{ "designation" => "test", "type" => "expression" }],
          "sources" => [source],
        },
      )
      subject.add_localization(l10n)
      expect(subject.find_source_by_id("smith-2020")).to eq(source)
    end

    it "skips sources without an id" do
      source = Glossarist::ConceptSource.new(
        type: "authoritative",
        origin: Glossarist::Citation.new(
          ref: Glossarist::Citation::Ref.new(source: "ISO", id: "7301"),
        ),
      )
      subject.sources = [source]
      expect(subject.find_source_by_id("ISO 7301")).to be_nil
    end

    it "finds a designation-level source by id" do
      source = Glossarist::ConceptSource.new(
        id: "term-source",
        type: "authoritative",
        origin: Glossarist::Citation.new(
          ref: Glossarist::Citation::Ref.new(source: "X"),
        ),
      )
      l10n = Glossarist::LocalizedConcept.of_yaml(
        "data" => {
          "language_code" => "eng",
          "terms" => [{
            "designation" => "test",
            "type" => "expression",
            "sources" => [source],
          }],
        },
      )
      subject.add_localization(l10n)
      expect(subject.find_source_by_id("term-source")).to eq(source)
    end
  end

  describe "#all_sources" do
    it "aggregates concept-level and l10n-level sources" do
      top = Glossarist::ConceptSource.new(
        type: "authoritative",
        origin: Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(source: "A")),
      )
      l10n_src = Glossarist::ConceptSource.new(
        type: "lineage",
        origin: Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(source: "B")),
      )
      subject.sources = [top]
      l10n = Glossarist::LocalizedConcept.of_yaml(
        "data" => {
          "language_code" => "eng",
          "terms" => [{ "designation" => "test", "type" => "expression" }],
          "sources" => [l10n_src],
        },
      )
      subject.add_localization(l10n)
      expect(subject.all_sources).to include(top, l10n_src)
    end
  end

  describe "identifier/uuid single source of truth" do
    it "identifier returns the same value as uuid" do
      expect(subject.identifier).to eq(subject.uuid)
    end

    it "id returns the same value as uuid" do
      expect(subject.id).to eq(subject.uuid)
    end

    it "setting identifier sets uuid" do
      subject.identifier = "test-uuid"
      expect(subject.uuid).to eq("test-uuid")
    end

    it "setting id sets uuid" do
      subject.id = "test-uuid-2"
      expect(subject.uuid).to eq("test-uuid-2")
    end

    it "persists identifier as uuid through YAML round-trip" do
      subject.uuid = "round-trip-id"
      restored = described_class.from_yaml(subject.to_yaml)
      expect(restored.uuid).to eq("round-trip-id")
      expect(restored.identifier).to eq("round-trip-id")
      expect(restored.id).to eq("round-trip-id")
    end
  end
end
