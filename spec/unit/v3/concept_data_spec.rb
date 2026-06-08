# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::ConceptData do
  describe "detailed_definition_fields" do
    it "includes definition, notes, examples, and annotations" do
      expect(described_class.detailed_definition_fields).to include(
        :definition, :notes, :examples, :annotations
      )
    end

    it "extends the base class fields" do
      base_fields = Glossarist::ConceptData.detailed_definition_fields
      v3_fields = described_class.detailed_definition_fields

      expect(v3_fields).to include(*base_fields)
      expect(v3_fields).to eq(base_fields + %i[annotations])
    end
  end

  describe "annotations attribute" do
    it "accepts annotation entries" do
      cd = described_class.new
      cd.annotations = [
        Glossarist::V3::DetailedDefinition.new(content: "editorial remark"),
        Glossarist::V3::DetailedDefinition.new(content: "committee note"),
      ]

      expect(cd.annotations.size).to eq(2)
      expect(cd.annotations.first.content).to eq("editorial remark")
      expect(cd.annotations.last.content).to eq("committee note")
    end

    it "round-trips through YAML" do
      cd = described_class.new(language_code: "eng")
      cd.definition = [Glossarist::V3::DetailedDefinition.new(content: "test def")]
      cd.annotations = [
        Glossarist::V3::DetailedDefinition.new(content: "an annotation"),
      ]

      yaml = cd.to_yaml
      restored = described_class.from_yaml(yaml)

      expect(restored.annotations.size).to eq(1)
      expect(restored.annotations.first.content).to eq("an annotation")
    end
  end

  describe "all_sources (via OCP)" do
    it "includes sources from annotations" do
      cd = described_class.new(language_code: "eng")
      source = Glossarist::V3::ConceptSource.new(type: "lineage")
      cd.annotations = [
        Glossarist::V3::DetailedDefinition.new(
          content: "annotation with source",
          sources: [source],
        ),
      ]

      expect(cd.all_sources).to include(source)
    end
  end

  describe "text_content (via OCP)" do
    it "includes annotation content" do
      cd = described_class.new(language_code: "eng")
      cd.annotations = [
        Glossarist::V3::DetailedDefinition.new(content: "important note"),
      ]

      expect(cd.text_content).to include("important note")
    end
  end

  describe "base class all_sources still works" do
    it "collects sources from definition, notes, and examples" do
      cd = Glossarist::ConceptData.new(language_code: "eng")
      source = Glossarist::ConceptSource.new(type: "authoritative")
      cd.definition = [
        Glossarist::DetailedDefinition.new(
          content: "a definition",
          sources: [source],
        ),
      ]

      expect(cd.all_sources).to include(source)
    end
  end
end
