# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::Locality do
  subject { described_class.new }

  let(:attrs) { { type: "clause", reference_from: "111" }.to_yaml }

  it "accepts strings as type" do
    expect { subject.type = "new one" }
      .to change { subject.type }.to("new one")
  end

  it "accepts strings as reference_from" do
    expect { subject.reference_from = "new one" }
      .to change { subject.reference_from }.to("new one")
  end

  it "accepts strings as reference_to" do
    expect { subject.reference_to = "new one" }
      .to change { subject.reference_to }.to("new one")
  end

  describe "#to_yaml" do
    context "dumps data to a hash" do
      it "dumps data with reference_from only" do
        test_yaml = described_class.new(type: "clause", reference_from: "5").to_yaml

        retval = YAML.safe_load(test_yaml)
        expect(retval).to be_kind_of(Hash)
        expect(retval["type"]).to eq("clause")
        expect(retval["reference_from"]).to eq("5")
        expect(retval["reference_to"]).to eq(nil)
      end

      it "dumps data with reference_from and reference_to" do
        test_yaml = described_class.new(
          type: "clause", reference_from: "5", reference_to: "10",
        ).to_yaml

        retval = YAML.safe_load(test_yaml)
        expect(retval).to be_kind_of(Hash)
        expect(retval["type"]).to eq("clause")
        expect(retval["reference_from"]).to eq("5")
        expect(retval["reference_to"]).to eq("10")
      end

      it "raise Lutaml::Model::ValidationError with invalid type" do
        test_yaml = described_class.new(type: "invalid", reference_from: "5")

        expect { test_yaml.validate! }.to raise_error(Lutaml::Model::ValidationError)
      end
    end
  end

  describe "#from_yaml" do
    it "loads data from yaml" do
      retval = described_class.from_yaml(attrs)

      expect(retval).to be_kind_of(Glossarist::Locality)
      expect(retval.type).to eq("clause")
      expect(retval.reference_from).to eq("111")
    end
  end
end
