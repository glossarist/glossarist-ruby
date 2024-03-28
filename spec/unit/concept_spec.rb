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

  it "accepts integers as ids" do
    expect { subject.id = 456 }
      .to change { subject.id }.to(456)
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

      retval = object.to_h["data"]
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

    it "generates a uuid if not given" do
      concept = described_class.new(attrs)
      uuid = Glossarist::Utilities::UUID.uuid_v5(
        Glossarist::Utilities::UUID::OID_NAMESPACE,
        concept.to_h.to_yaml
      )

      expect(concept.uuid).to eq(uuid)
    end

    it "assign a uuid if given" do
      concept = described_class.new(attrs.merge("uuid" => "abc"))

      expect(concept.uuid).to eq("abc")
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

  describe "#authoritative_source" do
    let(:attrs) do
      {
        id: "123",
        "sources" => [
          {
            "type" => "authoritative",
            "status" => "identical",
            "origin" => { "text" => "url" },
          },
          {
            "type" => "lineage",
            "status" => "identical",
            "origin" => { "text" => "url" },
          },
        ],
      }
    end

    let(:authoritative_source) do
      [
        {
          "type" => "authoritative",
          "status" => "identical",
          "origin" => {
            "ref" => "url",
          },
        },
      ]
    end

    it "should return only authoritative_sources" do
      expect(subject.authoritative_source.map(&:to_h))
        .to eq(authoritative_source)
    end
  end

  describe "#authoritative_source=" do
    let(:sources) do
      [
        {
          "type" => "authoritative",
          "status" => "identical",
          "origin" => { "ref" => "url" },
        },
        {
          "type" => "lineage",
          "status" => "identical",
          "origin" => { "ref" => "url" },
        },
      ]
    end

    let(:attrs) do
      {
        id: "123",
        "sources" => sources,
      }
    end

    let(:authoritative_source) do
      [
        {
          "type" => "authoritative",
          "status" => "identical",
          "origin" => {
            "ref" => "new url",
          },
        },
      ]
    end

    it "should add to sources hash" do

      expect { subject.authoritative_source = authoritative_source }
        .to change { subject.sources.map(&:to_h) }
        .from(sources)
        .to(sources + authoritative_source)
    end
  end
end
