# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::Citation do
  subject { described_class.from_yaml(attrs) }

  let(:attrs) { { text: "Citation" }.to_yaml }

  it "accepts strings as text" do
    expect { subject.text = "new one" }
      .to change { subject.text }.to("new one")
  end

  it "accepts strings as source" do
    expect { subject.source = "new one" }
      .to change { subject.source }.to("new one")
  end

  it "accepts strings as id" do
    expect { subject.id = "new one" }
      .to change { subject.id }.to("new one")
  end

  it "accepts strings as version" do
    expect { subject.version = "new one" }
      .to change { subject.version }.to("new one")
  end

  it "accepts strings as clause" do
    expect { subject.clause = "new one" }
      .to change { subject.clause }.to("new one")
  end

  it "accepts strings as link" do
    expect { subject.link = "new one" }
      .to change { subject.link }.to("new one")
  end

  it "accepts strings as original" do
    expect { subject.original = "new one" }
      .to change { subject.original }.to("new one")
  end

  describe "ref=" do
    it "accepts string as a ref" do
      expect { subject.ref = "new ref" }
        .to change { subject.text }.to("new ref")
    end

    it "accepts Hash as a ref" do
      ref = {
        "source" => "new source",
        "id" => "new id",
        "version" => "new version",
      }

      expect { subject.ref = ref }
        .to change { subject.source }.to("new source")
        .and change { subject.id }.to("new id")
        .and change { subject.version }.to("new version")
    end
  end

  describe "#to_h" do
    it "dumps plain text ref to a hash" do
      attrs.replace({
        text: "Example ref",
        clause: "12.3",
        link: "https://example.com",
        original: "original ref text",
      }.to_yaml)

      retval = YAML.safe_load(subject.to_yaml)
      expect(retval).to be_kind_of(Hash)
      expect(retval["ref"]).to eq("Example ref")
      expect(retval["clause"]).to eq("12.3")
      expect(retval["link"]).to eq("https://example.com")
      expect(retval["original"]).to eq("original ref text")
    end

    it "dumps structured ref to a hash" do
      attrs.replace({
        source: "Example source",
        id: "12345",
        version: "2020",
        clause: "12.3",
        link: "https://example.com",
        original: "original ref text",
      }.to_yaml)

      retval = YAML.safe_load(subject.to_yaml)

      expect(retval).to be_kind_of(Hash)
      expect(retval["ref"]["source"]).to eq("Example source")
      expect(retval["ref"]["id"]).to eq("12345")
      expect(retval["ref"]["version"]).to eq("2020")
      expect(retval["clause"]).to eq("12.3")
      expect(retval["link"]).to eq("https://example.com")
      expect(retval["original"]).to eq("original ref text")
    end

    it "dumps custom locality to a hash" do
      attrs.replace({
        source: "Example source",
        id: "12345",
        version: "2020",
        custom_locality: [
          { name: "version", value: "5" },
          { name: "schema", value: "3" },
        ],
      }.to_yaml)

      retval = YAML.safe_load(subject.to_yaml)

      expect(retval).to be_kind_of(Hash)
      expect(retval["ref"]["source"]).to eq("Example source")
      expect(retval["ref"]["id"]).to eq("12345")
      expect(retval["ref"]["version"]).to eq("2020")

      expect(retval["custom_locality"]).to be_kind_of(Array)
      expect(retval["custom_locality"].size).to eq(2)
      expect(retval["custom_locality"][0]).to be_kind_of(Hash)
      expect(retval["custom_locality"][0]["name"]).to eq("version")
      expect(retval["custom_locality"][0]["value"]).to eq("5")
      expect(retval["custom_locality"][1]).to be_kind_of(Hash)
      expect(retval["custom_locality"][1]["name"]).to eq("schema")
      expect(retval["custom_locality"][1]["value"]).to eq("3")
    end
  end

  describe "::from_h" do
    it "loads plain text ref from a hash" do
      src = {
        "ref" => "Citation",
        "clause" => "12.3",
        "link" => "https://example.com",
        "original" => "original ref text",
      }.to_yaml

      retval = described_class.from_yaml(src)

      expect(retval).to be_kind_of(Glossarist::Citation)
      expect(retval.text).to eq("Citation")
      expect(retval.clause).to eq("12.3")
      expect(retval.link).to eq("https://example.com")
    end

    it "loads structured ref from a hash" do
      src = {
        "ref" => {
          "source" => "Example source",
          "id" => "12345",
          "version" => "2020",
        },
        "clause" => "12.3",
        "link" => "https://example.com",
        "original" => "original ref text",
      }.to_yaml

      retval = described_class.from_yaml(src)

      expect(retval).to be_kind_of(Glossarist::Citation)
      expect(retval.source).to eq("Example source")
      expect(retval.id).to eq("12345")
      expect(retval.version).to eq("2020")
      expect(retval.clause).to eq("12.3")
      expect(retval.link).to eq("https://example.com")
    end

    it "loads custom locality from a hash" do
      src = {
        "ref" => {
          "source" => "Example source",
          "id" => "12345",
          "version" => "2020",
        },
        "custom_locality" => [
          { "name" => "version", "value" => "5" },
          { "name" => "schema", "value" => "3" },
        ],
      }.to_yaml

      retval = described_class.from_yaml(src)

      expect(retval).to be_kind_of(Glossarist::Citation)
      expect(retval.source).to eq("Example source")
      expect(retval.id).to eq("12345")
      expect(retval.version).to eq("2020")
      expect(retval.custom_locality).to be_kind_of(Array)
      expect(retval.custom_locality.size).to eq(2)
      expect(retval.custom_locality[0]).to be_kind_of(Glossarist::CustomLocality)
      expect(retval.custom_locality[0].name).to eq("version")
      expect(retval.custom_locality[0].value).to eq("5")
      expect(retval.custom_locality[1]).to be_kind_of(Glossarist::CustomLocality)
      expect(retval.custom_locality[1].name).to eq("schema")
      expect(retval.custom_locality[1].value).to eq("3")
    end
  end
end
