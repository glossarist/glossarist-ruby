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

  describe "#to_h" do
    it "dumps concept definition to a hash" do
      object = described_class.new(
        id: "123",
        related: [
          {
            content: "Test content",
            type: :supersedes,
          },
        ]
      )

      retval = object.to_h
      expect(retval).to be_kind_of(Hash)
      expect(retval["id"]).to eq("123")
      expect(retval["related"]).to eq([{"content"=>"Test content", "type"=>"supersedes"}])
    end
  end

  describe "::new" do
    it "accepts a hash of attributes" do
      expect { described_class.new(attrs) }
        .not_to raise_error
    end

    it "accepts a hash of attributes and create a concept" do
      related = [
        {
          "type" => "supersedes",
          "ref" => {
            "source" => "Example Source",
            "id" => "12345",
            "version" => "7",
          },
        },
      ]

      expected_hash = [
        {
          "type" => "supersedes",
          "ref" => {
            "source" => "Example Source",
            "id" => "12345",
            "version" => "7",
          },
        },
      ]
      subject.related = related

      expect(subject.related.first).to be_kind_of(Glossarist::RelatedConcept)
      expect(subject.related.first.to_h).to eq(expected_hash.first)
    end
  end

  describe "::from_h" do
    it "loads concept definition from a hash" do
      src = {
        "termid" => "123-45",
        "term" => "Example Designation",
        "sources" => [
          {
            "type" => "authoritative",
            "status" => "identical",
            "origin" => { "text" => "url" },
          }
        ],
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
        "eng" => { "some" => "English translation" },
        "deu" => { "some" => "German translation" },
      }

      retval = described_class.from_h(src)

      expect(retval).to be_kind_of(Glossarist::Concept)
      expect(retval.id).to eq("123-45")
      expect(retval.sources.size).to eq(1)
      expect(retval.sources.first.type).to eq("authoritative")
      expect(retval.sources.first.status).to eq("identical")
      expect(retval.sources.first.origin.to_h).to eq({ "ref" => "url" })
    end
  end
end
