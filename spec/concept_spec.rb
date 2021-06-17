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

  describe "::from_h" do
    it "loads concept definition from a Hash" do
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
        "eng" => {
          "id" => "123-45",
          "language_code" => "eng",
          "terms" => [
            {
              "designation" => "Example Designation",
              "type" => "expression",
              "normative_status" => "preferred",
            },
          ],
          "definition" => "Example Definition",
        },
      }

      retval = described_class.from_h(src)
      expect(retval).to be_kind_of(Glossarist::Concept)
      expect(retval.id).to eq("123-45")

      # TODO rather mock
      eng = retval.l10n("eng")
      expect(eng).to be_kind_of(Glossarist::LocalizedConcept)
      expect(eng.definition).to eq("Example Definition")
      expect(eng.terms.dig(0, "designation")).to eq("Example Designation")
      expect(eng.superseded_concepts.dig(0, "type")).to eq("supersedes")
      expect(eng.superseded_concepts.dig(0, "ref", "id")).to eq("12345")
    end
  end
end
