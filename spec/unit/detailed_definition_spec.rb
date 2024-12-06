# frozen_string_literal: true

RSpec.describe Glossarist::LutamlModel::DetailedDefinition do
  let(:detailed_definition) { Glossarist::LutamlModel::DetailedDefinition.new }

  describe "#content" do
    it "returns the content" do
      detailed_definition.content = "content"
      expect(detailed_definition.content).to eq("content")
    end
  end

  describe "#sources" do
    it "returns the sources" do
      source = Glossarist::LutamlModel::ConceptSource.from_yaml({
        "type" => "lineage",
        "status" => "identical",
        "origin" => { "text" => "origin" },
        "modification" => "note",
      }.to_yaml)

      detailed_definition.sources = [
        Glossarist::LutamlModel::ConceptSource.from_yaml({
          "type" => "lineage",
          "status" => "identical",
          "origin" => { "text" => "url" },
          "modification" => "some modification",
        }.to_yaml),
        source
      ]

      expect(detailed_definition.sources.size).to eq(2)
      expect(detailed_definition.sources.first).to be_a(Glossarist::LutamlModel::ConceptSource)
      expect(detailed_definition.sources.first.type).to eq("lineage")
      expect(detailed_definition.sources.first.status).to eq("identical")
      expect(detailed_definition.sources.first.origin.text).to eq("url")
      expect(detailed_definition.sources.first.modification).to eq("some modification")

      expect(detailed_definition.sources[1]).to be(source)
    end
  end

  describe "#to_yaml" do
    it "returns the yaml representation" do
      detailed_definition.content = "content"
      detailed_definition.sources = [
        Glossarist::LutamlModel::ConceptSource.from_yaml({
          type: "lineage",
          status: "identical",
          origin: { "text" => "origin" },
          modification: "some modification",
        }.to_yaml),
      ]

      expected_yaml = <<~YAML
        ---
        content: content
        sources:
        - origin:
            ref: origin
          status: identical
          type: lineage
          modification: some modification
      YAML

      expect(detailed_definition.to_yaml).to eq(expected_yaml)
    end
  end
end
