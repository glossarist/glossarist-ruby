# frozen_string_literal: true

RSpec.describe Glossarist::DetailedDefinition do
  let(:detailed_definition) { Glossarist::DetailedDefinition.new }

  describe "#content" do
    it "returns the content" do
      detailed_definition.content = "content"
      expect(detailed_definition.content).to eq("content")
    end
  end

  describe "#sources" do
    it "returns the sources" do
      source = Glossarist::ConceptSource.new({
        "type" => "lineage",
        "status" => "identical",
        "origin" => "url",
        "modification" => "note",
      })

      detailed_definition.sources = [
        {
          "type" => "lineage",
          "status" => "identical",
          "origin" => "url",
          "modification" => "some modification",
        },
        source
      ]

      expect(detailed_definition.sources.size).to eq(2)
      expect(detailed_definition.sources.first).to be_a(Glossarist::ConceptSource)
      expect(detailed_definition.sources.first.type).to eq(:lineage)
      expect(detailed_definition.sources.first.status).to eq(:identical)
      expect(detailed_definition.sources.first.origin).to eq("url")
      expect(detailed_definition.sources.first.modification).to eq("some modification")

      expect(detailed_definition.sources[1]).to be(source)
    end
  end

  describe "#to_h" do
    it "returns the hash representation" do
      detailed_definition.content = "content"
      detailed_definition.sources = [
        Glossarist::ConceptSource.new(
          "type" => "lineage",
          "status" => "identical",
          "origin" => "url",
          "modification" => "some modification",
        ),
      ]
      expect(detailed_definition.to_h).to eq({
        "content" => "content",
        "sources" => [
          {
            "type" => "lineage",
            "status" => "identical",
            "origin" => "url",
            "modification" => "some modification",
          },
        ],
      })
    end
  end
end
