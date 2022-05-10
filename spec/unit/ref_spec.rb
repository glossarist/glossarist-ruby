# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::Ref do
  subject { described_class.new attrs }

  let(:attrs) { { text: "some ref" } }

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

  describe "#to_h" do
    it "dumps plain text ref to a hash" do
      attrs.replace({
        text: "Example ref",
        clause: "12.3",
        link: "https://example.com",
        original: "original ref text",
      })

      retval = subject.to_h
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
      })

      retval = subject.to_h
      expect(retval).to be_kind_of(Hash)
      expect(retval["ref"]["source"]).to eq("Example source")
      expect(retval["ref"]["id"]).to eq("12345")
      expect(retval["ref"]["version"]).to eq("2020")
      expect(retval["clause"]).to eq("12.3")
      expect(retval["link"]).to eq("https://example.com")
      expect(retval["original"]).to eq("original ref text")
    end
  end

  describe "::from_h" do
    it "loads plain text ref from a hash" do
      src = {
        "ref" => "Some Ref",
        "clause" => "12.3",
        "link" => "https://example.com",
        "original" => "original ref text",
      }

      retval = described_class.from_h(src)
      expect(retval).to be_kind_of(Glossarist::Ref)
      expect(retval.text).to eq("Some Ref")
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
      }

      retval = described_class.from_h(src)
      expect(retval).to be_kind_of(Glossarist::Ref)
      expect(retval.source).to eq("Example source")
      expect(retval.id).to eq("12345")
      expect(retval.version).to eq("2020")
      expect(retval.clause).to eq("12.3")
      expect(retval.link).to eq("https://example.com")
    end
  end
end
