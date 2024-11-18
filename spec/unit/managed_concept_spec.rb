# frozen_string_literal: true

RSpec.describe Glossarist::ManagedConcept do
  subject { described_class.new(concept) }

  let(:concept) do
    {
      "data" => {
        "id" => "123",
        "localized_concepts" => {
          "ara" => "uuid",
        },
        "localizations" => [localized_concept],
        "groups" => [
          "foo",
          "bar",
        ],
        "status" => "valid",
      },
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
      subject.related = [{ "type" => "supersedes", "content" => "Example content" }]

      expect(subject.related.first.type).to eq("supersedes")
      expect(subject.related.first.content).to eq("Example content")
    end
  end

  describe "#dates=" do
    it "sets the dates" do
      subject.dates = [{ "type" => "accepted", "date" => "2020-01-01" }]

      expect(subject.dates.first.type).to eq("accepted")
      expect(subject.dates.first.date).to eq("2020-01-01")
    end
  end

  describe "#groups" do
    context "when string is given" do
      it "should convert it to array and set the groups list for the concept" do
        expect { subject.groups = "foobar" }
          .to change { subject.groups }.to(["foobar"])
      end
    end

    context "when array is given" do
      it "sets the groups list for the concept" do
        expect { subject.groups = ["general", "group"] }
          .to change { subject.groups }.to(["general", "group"])
      end
    end
  end

  describe "#sources" do
    let(:source) do
      {
        "status" => "identical",
        "origin" => { "text" => "Concept level source" },
      }
    end

    it "sets the sources list at the concept level" do
      expect(subject.sources).to be_nil

      subject.sources = [source]

      expect(subject.sources.first.status).to eq(source["status"])
      expect(subject.sources.first.origin.text).to eq(source["origin"]["text"])
    end
  end

  describe "#to_h" do
    let(:expected_concept_hash) do
      {
        "data" => {
          "identifier" => "123",
          "localized_concepts" => {
            "ara" => "uuid",
          },
          "groups" => [
            "foo",
            "bar",
          ],
        },
        "id" => "ebb21fa2-87a9-5895-84f6-37f022f4f550",
        "status" => "valid",
      }
    end

    it "dumps concept definition to a hash" do
      retval = subject.to_h

      expect(retval).to be_kind_of(Hash)
      expect(retval).to eq(expected_concept_hash)
    end
  end

  describe "#localizations_hash" do
    let(:expected_localizations_hash) do
      {
        "data" => {
          "identifier" => "123",
          "localized_concepts" => {
            "ara" => "uuid",
          },

          "groups" => [
            "foo",
            "bar",
          ],
        },
      }
    end

    it "dumps localizations to a hash" do
      localizations = subject.localizations_hash
      data = localizations["ara"]["data"]

      expect(localizations).to be_kind_of(Hash)
      expect(data["terms"]).to eq([{ "type" => "expression", "designation" => "Arabic Designation" }])
      expect(data["dates"]).to eq([{ "type" => "accepted", "date" => "2020-01-01" }])
    end
  end

  describe "#localized_concepts=" do
    let(:localized_concepts_hash) do
      [
        {
          "language_code" => "eng",
          "definition" => [
            {
              "content" => "this is very important",
            },
          ],
          "entry_status" => "valid",
        },
      ]
    end

    it "accepts a hash" do
      expect { subject.localized_concepts = localized_concepts_hash }
        .not_to raise_error
    end

    it "accepts a hash of attributes and create a concept" do
      subject.localized_concepts = localized_concepts_hash

      expect(subject.localized_concepts).to be_a(Hash)
    end

    it "should have same uuid in localized concept hash and the localized concept" do
      subject.localized_concepts = localized_concepts_hash

      expect(subject.localization("eng").uuid).to eq(subject.localized_concepts["eng"])
    end
  end

  describe "#localizations=" do
    let(:localizations_hash) do
      [
        {
          "id" => "123",
          "language_code" => "eng",
          "definition" => [
            {
              "content" => "this is very important",
            },
          ],
          "entry_status" => "valid",
        },
      ]
    end

    it "accepts a hash" do
      expect { subject.localizations = localizations_hash }
        .not_to raise_error
    end

    it "accepts a hash of attributes and create a concept" do
      subject.localized_concepts = localizations_hash

      expect(subject.localizations).to be_a(Hash)
      expect(subject.localizations["eng"]).to be_a(Glossarist::LocalizedConcept)
      expect(subject.localizations["eng"].definition.first.content).to eq("this is very important")
      expect(subject.localizations["eng"].entry_status).to eq("valid")
    end
  end

  describe "#default_designation" do
    it "returns first English designation when available" do
      localized_concept = Glossarist::LocalizedConcept.new(
        "language_code" => "eng",
        "terms" => [
          {
            "designation" => "English Designation",
            "type" => "expression",
          },
        ],
      )
      object = described_class.new("data" => { id: "123" })
      object.add_l10n(localized_concept)

      expect(object.default_designation).to eq("English Designation")
    end

    it "retunrs any designation when English localization is missing" do
      expect(subject.default_designation).to eq("Arabic Designation")
    end
  end
end
