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

  %w[
    deprecated_concepts superseded_concepts narrower_concepts broader_concepts
    equivalent_concepts comparable_concepts contrasting_concepts
    see_also_concepts
  ].each do |attr_name|
    describe "##{attr_name}" do
      let(:sup) { instance_double(Glossarist::Ref) }

      it "is an array of refs" do
        expect { subject.send(attr_name) << sup }
          .to change { subject.send(attr_name) }.to([sup])
      end
    end
  end

  describe "#related_concepts" do
    it "returns an array of all related concepts, disregarding relation type" do
      refs = 4.times.map { |n| instance_double(Glossarist::Ref, "ref #{n}") }

      subject.superseded_concepts << refs[0]
      subject.narrower_concepts << refs[1]
      subject.see_also_concepts << refs[2] << refs[3]

      expect(subject.related_concepts).to contain_exactly(*refs)
    end
  end

  describe "#default_designation" do
    it "returns first English designation when available" do
      object = described_class.new(id: "123")

      object.localizations["ara"] = double(
        terms: [
          double(designation: "in Arabic"), double(designation: "in Arabic 2")
        ]
      )

      object.localizations["eng"] = double(
        terms: [
          double(designation: "in English"), double(designation: "in English 2")
        ]
      )

      object.localizations["deu"] = double(
        terms: [
          double(designation: "in German"), double(designation: "in German 2")
        ]
      )

      expect(object.default_designation).to eq("in English")
    end

    it "retunrs any designation when English localization is missing" do
      object = described_class.new(id: "123")

      object.localizations["ara"] = double(
        terms: [
          double(designation: "in Arabic"), double(designation: "in Arabic 2")
        ]
      )

      object.localizations["deu"] = double(
        terms: [
          double(designation: "in German"), double(designation: "in German 2")
        ]
      )

      expect(object.default_designation).to eq("in Arabic") || eq("in German")
    end
  end

  describe "#to_h" do
    it "dumps concept definition to a hash" do
      object = described_class.new(
        id: "123",
        superseded_concepts: [{"some" => "supersession"}],
      )

      object.localizations["eng"] = double(
        to_h: {"some" => "eng translation"},
      )

      object.localizations["deu"] = double(
        to_h: {"some" => "deu translation"},
      )

      allow(object).to receive(:default_designation).and_return("default term")

      retval = object.to_h
      expect(retval).to be_kind_of(Hash)
      expect(retval["termid"]).to eq("123")
      expect(retval["term"]).to eq("default term")
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

      eng_dbl = double(language_code: "eng")
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
      expect(retval.superseded_concepts.dig(0, "type")).to eq("supersedes")
      expect(retval.superseded_concepts.dig(0, "ref", "id")).to eq("12345")
    end
  end
end
