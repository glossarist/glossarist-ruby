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
    expect { subject.definition = "this is very important" }
      .to change { subject.definition }.to("this is very important")
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

  describe "#superseded_concepts" do
    let(:sup) { double("supersession") }

    it "is an array" do
      expect { subject.superseded_concepts << sup }
        .to change { subject.superseded_concepts }.to([sup])
    end
  end

  describe "#to_h" do
    it "dumps localized concept definition to a hash" do
      attrs.replace({
        id: "123",
        language_code: "lang",
        terms: [{"some" => "designation"}, {"another" => "designation"}],
        examples: ["ex. one"],
        notes: ["note one"],
        authoritative_source: [{"source" => "reference"}],
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
        "definition" => "Example Definition",
        "authoritative_source" => [
          {"Example Source" => "Reference"},
        ],
      }

      retval = described_class.from_h(src)
      expect(retval).to be_kind_of(Glossarist::LocalizedConcept)
      expect(retval.definition).to eq("Example Definition")
      expect(retval.terms.dig(0, "designation")).to eq("Example Designation")
      expect(retval.authoritative_source).to eq([{"Example Source" => "Reference"}])
    end
  end
end
