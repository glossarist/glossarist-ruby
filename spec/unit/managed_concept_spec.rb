# frozen_string_literal: true

RSpec.describe Glossarist::ManagedConcept do
  subject { described_class.new attrs }

  let(:attrs) do
    {
      "id" => "123",
      "localized_concepts" => [
        {
          "language_code" => "ara",
          "terms" => [
            {
              "designation" => "Arabic Designation",
              "type" => "expression",
            },
          ],
        },
      ],

      "dates" => [
        {
          "type" => "accepted",
          "date" => "2020-01-01",
        },
      ],
    }
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

  describe "#to_h" do
    it "dumps concept definition to a hash" do
      retval = subject.to_h

      expect(retval).to be_kind_of(Hash)
      expect(retval["termid"]).to eq("123")
      expect(retval["term"]).to eq("Arabic Designation")
      expect(retval["ara"]).to eq({"terms"=>[{"type"=>"expression", "designation"=>"Arabic Designation"}], "notes"=>[], "examples"=>[], "language_code"=>"ara"})
      expect(retval["dates"]).to eq([{"date"=>"2020-01-01", "type"=>"accepted"}])
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

    it "accepts a hash of attributes" do
      expect { subject.localized_concepts = localized_concepts_hash }
        .not_to raise_error
    end

    it "accepts a hash of attributes and create a concept" do
      subject.localized_concepts = localized_concepts_hash

      expect(subject.localized_concepts.first).to be_a(Glossarist::LocalizedConcept)
      expect(subject.localized_concepts.first.language_code).to eq("eng")
      expect(subject.localized_concepts.first.definition.first.content).to eq("this is very important")
      expect(subject.localized_concepts.first.entry_status).to eq("valid")
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
      object = described_class.new(id: "123")
      object.add_l10n(localized_concept)

      expect(object.default_designation).to eq("English Designation")
    end

    it "retunrs any designation when English localization is missing" do
      object = described_class.new(attrs)

      expect(object.default_designation).to eq("Arabic Designation")
    end
  end
end
