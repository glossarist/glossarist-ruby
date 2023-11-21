# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::LocalizedConcept do
  subject { described_class.new attrs }

  let(:attrs) { { language_code: "eng" } }

  it "accepts strings as ids" do
    expect { subject.id = "456" }
      .to change { subject.id }.to("456")
  end

  it "raises error if id is not a `String`" do
    expect { subject.id = 1234 }
      .to raise_error(Glossarist::Error, "Expect id to be a string, Got Integer (1234)")
  end

  it "accepts strings as language codes" do
    expect { subject.language_code = "deu" }
      .to change { subject.language_code }.to("deu")
  end

  it "raises error if language_code is not 3 characters long" do
    expect { subject.language_code = "urdu" }
      .to raise_error(Glossarist::InvalidLanguageCodeError)
  end

  it "accepts strings as definitions" do
    definition = Glossarist::DetailedDefinition.new({ content: "this is very important" })

    expect { subject.definition = [ definition ] }
      .to change { subject.definition.count }.from(0).to(1)
  end

  it "accepts strings as entry statuses" do
    expect { subject.entry_status = "valid" }
      .to change { subject.entry_status }.to("valid")
  end

  it "accepts strings as classifications" do
    expect { subject.classification = "admitted" }
      .to change { subject.classification }.to("admitted")
  end

  it "accepts strings as review dates" do
    expect { subject.review_date = "2020-01-01" }
      .to change { subject.review_date }.to("2020-01-01")
  end

  it "accepts strings as review decision dates" do
    expect { subject.review_decision_date = "2020-01-01" }
      .to change { subject.review_decision_date }.to("2020-01-01")
  end

  it "accepts strings as review decision events" do
    expect { subject.review_decision_event = "published" }
      .to change { subject.review_decision_event }.to("published")
  end

  describe "#designations" do
    let(:expression) { { "type" => "expression", designation: "expression designation" } }

    it "is a collection of designations" do
      expect { subject.designations << expression }
        .to change { subject.designations.count }.from(0).to(1)
    end

    it "is aliased as 'terms'" do
      expect { subject.designations << expression }
        .to change { subject.terms.count }.from(0).to(1)
    end
  end

  describe "#notes" do
    it "adds a note of type DetailedDefinition" do
      expect { subject.notes << "str" }
        .to change { subject.notes.count }.from(0).to(1)
        .and change { subject.notes.first.class }.from(NilClass).to(Glossarist::DetailedDefinition)
    end
  end

  describe "#examples" do
    it "adds an example of type DetailedDefinition" do
      expect { subject.examples << "example" }
        .to change { subject.examples.count }.from(0).to(1)
        .and change { subject.examples.first.class }.from(NilClass).to(Glossarist::DetailedDefinition)
    end
  end

  describe "#sources" do
    let(:item) { { "text" => "source" } }

    it "is an array" do
      expect { subject.sources << item }
        .to change { subject.sources.count }.from(0).to(1)
    end
  end

  describe "#to_h" do
    it "dumps localized concept definition to a hash" do
      term1 = { "type" => "expression", "designation" => "term1" }
      term2 = { "type" => "expression", "designation" => "term2" }
      source = { "type" => "authoritative", "status" => "modified" }
      attrs.replace({
        id: "123",
        language_code: "eng",
        terms: [term1, term2],
        examples: ["ex. one"],
        notes: ["note one"],
        sources: [source],
      })

      retval = subject.to_h["data"]
      expect(retval).to be_kind_of(Hash)
      expect(retval["language_code"]).to eq("eng")
      expect(retval["id"]).to eq("123")
      expect(retval["terms"]).to eq([term1, term2])
      expect(retval["examples"]).to eq([{ "content" => "ex. one"}])
      expect(retval["notes"]).to eq([{ "content" => "note one"}])
      expect(retval["sources"]).to eq([source])
    end
  end

  describe "::from_h" do
    it "loads localized concept definition from a hash" do
      source = { "source" => "wikipedia", "id" => "123", "version" => "71" }

      src = {
        "id" => "123-45",
        "language_code" => "eng",
        "terms" => [
          {
            "designation" => "Example Designation",
            "type" => "expression",
            "normative_status" => "preferred",
          },
        ],
        "definition" => [{ content: "Example Definition" }],
        "authoritative_source" => [source],
      }

      retval = described_class.from_h(src)

      expect(retval).to be_kind_of(Glossarist::LocalizedConcept)
      expect(retval.id).to eq("123-45")
      expect(retval.definition.size).to eq(1)
      expect(retval.definition.first.content).to eq("Example Definition")
      expect(retval.terms.collection).to eq([])
      expect(retval.sources.map(&:to_h)).to eq([{ "origin" => { "ref" => source }, "type" => "" }])
    end

    it "should work iev-data for grammar_info" do
      src = {
        "id" => "103-01-12",
        "language_code" => "eng",
        "terms" => [
          {
            "designation" => "Intervall",
            "type" => "expression",
            "normative_status" => "preferred",
            "part_of_speech" => "adj",
            "gender" => "n",
            "plurality" => "singular",
          },
        ],
        "definition" => [{ content: "set of real numbers such that, for any pair (stem:[x], stem:[y]) of elements of the set, any real number stem:[z] between stem:[x] and stem:[y] belongs to the set" }],
      }

      localized_concept = Glossarist::LocalizedConcept.new(src)
      grammar_info = localized_concept.designations.first.grammar_info.first

      expect(grammar_info.n?).to be(true)
      expect(grammar_info.adj?).to be(true)
      expect(grammar_info.singular?).to be(true)
    end
  end
end
