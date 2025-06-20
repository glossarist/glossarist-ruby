# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::CustomLocality do
  subject { described_class.new }

  let(:attrs) { { name: "version", value: "5" }.to_yaml }

  it "accepts strings as name" do
    expect { subject.name = "new one" }
      .to change { subject.name }.to("new one")
  end

  it "accepts strings as value" do
    expect { subject.value = "new one" }
      .to change { subject.value }.to("new one")
  end

  describe "#to_yaml" do
    it "dumps data to a hash" do
      test_yaml = described_class.new(name: "version", value: "5").to_yaml

      retval = YAML.safe_load(test_yaml)
      expect(retval).to be_kind_of(Hash)
      expect(retval["name"]).to eq("version")
      expect(retval["value"]).to eq("5")
    end
  end

  describe "#from_yaml" do
    it "loads data from yaml" do
      retval = described_class.from_yaml(attrs)

      expect(retval).to be_kind_of(Glossarist::CustomLocality)
      expect(retval.name).to eq("version")
      expect(retval.value).to eq("5")
    end
  end
end
