# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::Designation::Expression do
  subject { described_class.new attrs }

  let(:attrs) { { designation: "equality", normative_status: :preferred, grammar_info: [{}] } }

  it "accepts strings as designations" do
    expect { subject.designation = "new one" }
      .to change { subject.designation }.to("new one")
  end

  it "accepts strings as normative statuses" do
    expect { subject.normative_status = "admitted" }
      .to change { subject.normative_status }.to("admitted")
  end

  it "accepts strings as plurality values" do
    expect { subject.grammar_info.first.number = "plural" }
      .to change { subject.grammar_info.first.number }.to(["plural"])
  end

  it "accepts strings as genders" do
    expect { subject.grammar_info.first.gender = "m" }
      .to change { subject.grammar_info.first.gender }.to(["m"])
  end

  it "accepts strings as parts of speech" do
    expect { subject.grammar_info.first.part_of_speech = "adj" }
      .to change { subject.grammar_info.first.adj }.to(true)
  end

  describe "#to_h" do
    it "dumps designation to a hash" do
      attrs.replace({
        designation: "Example designation",
        normative_status: "preferred",
        geographical_area: "somewhere",
        grammar_info: [{
          gender: "m",
          part_of_speech: "adj",
          number: "singular",
        }],
        usage_info: "science",
      })

      retval = subject.to_h
      expect(retval).to be_kind_of(Hash)
      expect(retval["type"]).to eq("expression")
      expect(retval["designation"]).to eq("Example designation")
      expect(retval["normative_status"]).to eq("preferred")
      expect(retval["geographical_area"]).to eq("somewhere")
      expect(retval["grammar_info"].first["gender"]).to eq(["m"])
      expect(retval["grammar_info"].first["adj"]).to eq(true)
      expect(retval["grammar_info"].first["number"]).to eq(["singular"])
      expect(retval["usage_info"]).to eq("science")
    end
  end

  describe "::from_h" do
    it "loads localized concept definition from a hash" do
      src = {
        "type" => "expression",
        "designation" => "Example Designation",
        "normative_status" => "preferred",
      }

      retval = described_class.from_h(src)
      expect(retval).to be_kind_of(Glossarist::Designation::Expression)
      expect(retval.designation).to eq("Example Designation")
      expect(retval.normative_status).to eq("preferred")
    end
  end
end

RSpec.describe Glossarist::Designation::Symbol do
  subject { described_class.new attrs }

  let(:attrs) { { designation: "sym", normative_status: :preferred } }

  it "accepts strings as designations" do
    expect { subject.designation = "new one" }
      .to change { subject.designation }.to("new one")
  end

  it "accepts strings as normative statuses" do
    expect { subject.normative_status = "admitted" }
      .to change { subject.normative_status }.to("admitted")
  end

  describe "#to_h" do
    it "dumps designation to a hash" do
      attrs.replace({
        designation: "X",
        normative_status: "preferred",
        geographical_area: "somewhere",
        international: true,
      })

      retval = subject.to_h
      expect(retval).to be_kind_of(Hash)
      expect(retval["type"]).to eq("symbol")
      expect(retval["designation"]).to eq("X")
      expect(retval["normative_status"]).to eq("preferred")
      expect(retval["geographical_area"]).to eq("somewhere")
      expect(retval["international"]).to be(true)
    end
  end

  describe "::from_h" do
    it "loads localized concept definition from a hash" do
      src = {
        "type" => "symbol",
        "designation" => "Example Symbol",
        "normative_status" => "preferred",
      }

      retval = described_class.from_h(src)
      expect(retval).to be_kind_of(Glossarist::Designation::Symbol)
      expect(retval.designation).to eq("Example Symbol")
      expect(retval.normative_status).to eq("preferred")
    end
  end
end
