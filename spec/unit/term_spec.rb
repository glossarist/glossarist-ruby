# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::Term do
  subject { described_class.new attrs }

  let(:attrs) { { "definition" => "some definition" } }

  it "accepts string as definition" do
    expect { subject.definition = "new definition" }
      .to change { subject.definition }.to("new definition")
  end

  it "accepts string as acronym" do
    expect { subject.acronym = "new acronym" }
      .to change { subject.acronym }.to("new acronym")
  end

  it "accepts strings as id" do
    expect { subject.synonyms = "new synonym 1, new synonym 2" }
      .to change { subject.synonyms }.to("new synonym 1, new synonym 2")
  end

  describe "#to_h" do
    it "dumps term to a hash" do
      attrs.replace({
        "definition" => "Definition of Term",
        "acronym" => "DoT",
        "synonyms" => "Def of t",
      })

      retval = subject.to_h
      expect(retval).to be_kind_of(Hash)
      expect(retval["definition"]).to eq("Definition of Term")
      expect(retval["acronym"]).to eq("DoT")
      expect(retval["synonyms"]).to eq("Def of t")
    end
  end

  describe "::from_h" do
    it "loads term from a hash" do
      src = {
        "definition" => "Definition of Term (DoT)",
        "synonyms" => "Def of t",
      }

      retval = described_class.from_h(src)
      expect(retval).to be_kind_of(Glossarist::Term)
      expect(retval.definition).to eq("Definition of Term ")
      expect(retval.acronym).to eq("DoT")
      expect(retval.synonyms).to eq("Def of t")
    end
  end
end
