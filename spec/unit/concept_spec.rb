# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::LutamlModel::Concept do
  subject { described_class.from_yaml(attrs) }

  let(:attrs) { { id: "123" }.to_yaml }

  it "accepts strings as ids" do
    expect { subject.id = "456" }.to change { subject.id }.to("456")
  end

  # it "accepts integers as ids" do
  #   expect { subject.id = 456 }.to change { subject.id }.to(456)
  # end

  describe "#to_yaml" do
    it "dumps concept definition to a hash" do
      object = described_class.from_yaml(
        {
          id: "123",
          related: [
            {
              content: "Test content",
              type: :supersedes,
            },
          ],
        }.to_yaml
      )

      retval = YAML.load(object.to_yaml)["data"]

      expect(retval).to be_kind_of(Hash)
      expect(retval["id"]).to eq("123")
      expect(retval["related"]).to eq([{ "content" => "Test content", "type" => "supersedes" }])
    end
  end

  describe "::new" do
    it "accepts yaml of attributes" do
      expect { described_class.from_yaml(attrs) }.not_to raise_error
    end

    it "generates a uuid if not given" do
      concept = described_class.from_yaml(attrs)

      uuid = Glossarist::Utilities::UUID.uuid_v5(
        Glossarist::Utilities::UUID::OID_NAMESPACE,
        concept.data_hash(concept).to_yaml
      )

      expect(concept.uuid).to eq(uuid)
    end

    it "assign a uuid if given" do
      concept = described_class.from_yaml(attrs)
      concept.uuid = "abc"

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

      expect(subject.related.first).to be_kind_of(Glossarist::LutamlModel::RelatedConcept)
      expect(YAML.load(subject.related.first.to_yaml)).to eq(expected_hash.first)
    end

    describe "when authoritative_source and source both present" do
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
          "id" => "123",
          "sources" => sources,
          "authoritative_source" => [
            { "link" => "source url" },
          ],
          "authoritativeSource" => [
            { "link" => "source url" },
          ],
        }.to_yaml
      end

      it "should skip authoritative_source" do
        expect(subject.sources.map { |source| YAML.load(source.to_yaml) }).to eq(sources)
      end
    end
  end

  describe "::from_yaml" do
    it "loads concept definition from a yaml" do
      src = {
        "termid" => "123-45",
        "term" => "Example Designation",
        "sources" => [
          {
            "type" => "authoritative",
            "status" => "identical",
            "origin" => { "text" => "url" },
          },
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
      }.to_yaml

      retval = described_class.from_yaml(src)

      expect(retval).to be_kind_of(Glossarist::LutamlModel::Concept)
      expect(retval.id).to eq("123-45")
      expect(retval.sources.size).to eq(1)
      expect(retval.sources.first.type).to eq("authoritative")
      expect(retval.sources.first.status).to eq("identical")
      expect(YAML.load(retval.sources.first.origin.to_yaml)).to eq({ "ref" => "url" })
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
      }.to_yaml
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
      expect(subject.authoritative_source.map { |auth_source| YAML.load(auth_source.to_yaml) }).to eq(authoritative_source)
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
      }.to_yaml
    end

    let(:authoritative_source) do
      {
        "status" => "identical",
        "origin" => {
          "ref" => "new url",
        },
      }
    end

    it "should add to sources hash" do
      expect { subject.authoritative_source = [authoritative_source] }.to change { subject.sources.map { |source| YAML.load(source.to_yaml) } }
          .from(sources)
          .to(sources + [authoritative_source.merge("type" => "authoritative")])
    end
  end
end
