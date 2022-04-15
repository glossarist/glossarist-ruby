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

  it "accepts strings as language codes" do
    expect { subject.language_code = "deu" }
      .to change { subject.language_code }.to("deu")
  end

  it "accepts strings as definitions" do
    definition = Glossarist::DetailedDefinition.new({ content: "this is very important" })

    expect { subject.definition = [ definition ] }
      .to change { subject.definition }.to([ definition ])
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

  it "accepts strings as dates accepted" do
    expect { subject.date_accepted = "2020-01-01" }
      .to change { subject.date_accepted }.to("2020-01-01")
  end

  it "accepts strings as dates amended" do
    expect { subject.date_amended = "2020-01-01" }
      .to change { subject.date_amended }.to("2020-01-01")
  end

  describe "#designations" do
    let(:expression) { double("expression designation") }

    it "is an array of designations" do
      expect { subject.designations << expression }
        .to change { subject.designations }.to([expression])
    end

    it "is aliased as 'terms'" do
      expect { subject.designations << expression }
        .to change { subject.terms }.to([expression])
    end
  end

  describe "#notes" do
    it "is an array of strings" do
      expect { subject.notes << "str" }
        .to change { subject.notes }.to(["str"])
    end
  end

  describe "#examples" do
    it "is an array of strings" do
      expect { subject.examples << "str" }
        .to change { subject.examples }.to(["str"])
    end
  end

  describe "#sources" do
    let(:item) { double("source") }

    it "is an array" do
      expect { subject.sources << item }
        .to change { subject.sources }.to([item])
    end
  end

  describe "#to_h" do
    it "dumps localized concept definition to a hash" do
      term1 = double(to_h: {"some" => "designation"})
      term2 = double(to_h: {"another" => "designation"})
      source = double(to_h: {"source" => "reference"})
      attrs.replace({
        id: "123",
        language_code: "lang",
        terms: [term1, term2],
        examples: ["ex. one"],
        notes: ["note one"],
        sources: [source],
      })

      retval = subject.to_h
      expect(retval).to be_kind_of(Hash)
      expect(retval["language_code"]).to eq("lang")
      expect(retval["id"]).to eq("123")
      expect(retval["terms"]).to eq([
        {"some" => "designation"}, {"another" => "designation"}])
      expect(retval["examples"]).to eq(["ex. one"])
      expect(retval["notes"]).to eq(["note one"])
      expect(retval["authoritative_source"]).to eq([{"source" => "reference"}])
    end
  end

  describe "::from_h" do
    it "loads localized concept definition from a hash" do
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
        "authoritative_source" => [
          {"Example Source" => "Reference"},
        ],
      }

      expr_dbl = double("expression")
      source_dbl = double("source")

      expect(Glossarist::Designation::Base)
        .to receive(:from_h)
        .with(src["terms"][0])
        .and_return(expr_dbl)

      expect(Glossarist::Ref)
        .to receive(:from_h)
        .with({"Example Source" => "Reference"})
        .and_return(source_dbl)

      retval = described_class.from_h(src)
      expect(retval).to be_kind_of(Glossarist::LocalizedConcept)
      expect(retval.definition.size).to eq(1)
      expect(retval.definition.first.content).to eq("Example Definition")
      expect(retval.terms).to eq([expr_dbl])
      expect(retval.sources).to eq([source_dbl])
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

      localized_concept = Glossarist::LocalizedConcept.from_h(src)
      grammar_info = localized_concept.designations.first.grammar_info.first

      expect(grammar_info.n?).to be(true)
      expect(grammar_info.adj?).to be(true)
      expect(grammar_info.singular?).to be(true)
    end
  end
end
