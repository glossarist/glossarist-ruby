# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::Concept do
  subject { described_class.new attrs }

  let(:attrs) { { id: "123" } }

  it "accepts strings as ids" do
    expect { subject.id = "456" }
      .to change { subject.id }.to("456")
  end

  describe "#localizations" do
    let(:eng) { Glossarist::LocalizedConcept.new }

    it "is an array of localized concepts" do
      expect { subject.localizations.merge! "eng" => eng }
        .to change { subject.localizations }.to({ "eng" => eng })
    end
  end

  describe "#to_h" do
    it "dumps concept definition to a hash" do
      object = described_class.new(id: "123")

      object.localizations["eng"] = double(
        to_h: {"some" => "eng translation"},
        terms: [{"designation" => "term in English"}],
        superseded_concepts: [{"some" => "supersession"}],
      )

      object.localizations["deu"] = double(
        to_h: {"some" => "deu translation"},
        terms: [{"designation" => "term in German"}],
        superseded_concepts: [],
      )

      retval = object.to_h
      expect(retval).to be_kind_of(Hash)
      expect(retval["termid"]).to eq("123")
      expect(retval["term"]).to eq("term in English")
      expect(retval["related"]).to eq([{"some" => "supersession"}])
      expect(retval["eng"]).to eq({"some" => "eng translation"})
      expect(retval["deu"]).to eq({"some" => "deu translation"})
    end
  end

  describe "::from_h" do
    it "loads concept definition from a hash" do
      src = {
        "termid" => "123-45",
        "term" => "Example Designation",
        "related" => [
          {
            "type" => "supersedes",
            "ref" => {
              "source" => "Example Source",
              "id" => "12345",
              "version" => "7",
            },
          },
        ],
        "eng" => { "some" => "English translation" },
        "deu" => { "some" => "German translation" },
      }

      eng_dbl = double(language_code: "eng", :"superseded_concepts=" => [])
      deu_dbl = double(language_code: "deu")

      expect(Glossarist::LocalizedConcept)
        .to receive(:from_h)
        .with({ "some" => "English translation" })
        .and_return(eng_dbl)

      expect(Glossarist::LocalizedConcept)
        .to receive(:from_h)
        .with({ "some" => "German translation" })
        .and_return(deu_dbl)

      retval = described_class.from_h(src)

      expect(retval).to be_kind_of(Glossarist::Concept)
      expect(retval.id).to eq("123-45")
      expect(retval.l10n("eng")).to be(eng_dbl)
      expect(retval.l10n("deu")).to be(deu_dbl)
    end
  end
end
