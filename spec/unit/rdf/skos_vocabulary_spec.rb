# frozen_string_literal: true

require "spec_helper"
require "lutaml/jsonld"
require "lutaml/turtle"
require "glossarist/rdf"

RSpec.describe Glossarist::Rdf::SkosVocabulary do
  let(:label_en) do
    Glossarist::Rdf::LocalizedLiteral.new(value: "geodetic latitude",
                                          language_code: "eng")
  end

  let(:label_deu) do
    Glossarist::Rdf::LocalizedLiteral.new(value: "geodätische Breite",
                                          language_code: "deu")
  end

  let(:concept_1) do
    Glossarist::Rdf::SkosConcept.new(
      code: "200",
      labels: [label_en, label_deu],
      definitions: [
        Glossarist::Rdf::LocalizedLiteral.new(
          value: "angle from the equatorial plane", language_code: "eng",
        ),
      ],
      sources: ["ISO 19111:2019"],
    )
  end

  let(:concept_2) do
    Glossarist::Rdf::SkosConcept.new(
      code: "888",
      labels: [
        Glossarist::Rdf::LocalizedLiteral.new(value: "intension",
                                              language_code: "eng"),
      ],
      sources: ["ISO 1087-1:2000"],
    )
  end

  subject(:vocabulary) do
    described_class.new(
      id: "iso1087",
      title: "ISO 1087",
      concepts: [concept_1, concept_2],
    )
  end

  describe "attributes" do
    it "has an id" do
      expect(vocabulary.id).to eq("iso1087")
    end

    it "has a title" do
      expect(vocabulary.title).to eq("ISO 1087")
    end

    it "has concepts as a collection" do
      expect(vocabulary.concepts.size).to eq(2)
    end
  end

  describe "rdf mappings" do
    it "has members declaration" do
      mapping = described_class.mappings[:turtle]
      expect(mapping.rdf_members.size).to eq(1)
      expect(mapping.rdf_members.first.attr_name).to eq(:concepts)
    end

    it "has a subject block" do
      mapping = described_class.mappings[:turtle]
      expect(mapping.rdf_subject).to be_a(Proc)
    end

    it "has type set to skos:ConceptScheme" do
      mapping = described_class.mappings[:turtle]
      expect(mapping.rdf_type).to eq("skos:ConceptScheme")
    end
  end

  describe "#to_turtle" do
    subject(:turtle) { vocabulary.to_turtle }

    it "includes prefix declarations" do
      expect(turtle).to include("@prefix skos:")
      expect(turtle).to include("@prefix dcterms:")
    end

    it "includes ConceptScheme type" do
      expect(turtle).to include("a skos:ConceptScheme")
    end

    it "includes vocabulary URI" do
      expect(turtle).to include("<https://glossarist.org/vocab/iso1087>")
    end

    it "includes vocabulary title" do
      expect(turtle).to include('skos:prefLabel "ISO 1087"')
    end

    it "includes all member concepts" do
      expect(turtle).to include("skos:notation \"200\"")
      expect(turtle).to include("skos:notation \"888\"")
    end

    it "includes member concept labels" do
      expect(turtle).to match(/"geodetic latitude"@eng/)
      expect(turtle).to match(/"geodätische Breite"@deu/)
      expect(turtle).to match(/"intension"@eng/)
    end

    it "includes member concept sources" do
      expect(turtle).to include("ISO 19111:2019")
      expect(turtle).to include("ISO 1087-1:2000")
    end
  end

  describe "#to_jsonld" do
    subject(:jsonld) { JSON.parse(vocabulary.to_jsonld) }

    it "includes @context with namespace prefixes" do
      expect(jsonld["@context"]).to include("skos", "dcterms")
    end

    it "includes @graph array" do
      expect(jsonld["@graph"]).to be_an(Array)
    end

    it "includes ConceptScheme in @graph" do
      scheme = jsonld["@graph"].find { |r| r["@type"] == "skos:ConceptScheme" }
      expect(scheme).not_to be_nil
      expect(scheme["@id"]).to eq("https://glossarist.org/vocab/iso1087")
      expect(scheme["prefLabel"]).to eq("ISO 1087")
    end

    it "includes all member concepts in @graph" do
      concepts = jsonld["@graph"].select { |r| r["@type"] == "skos:Concept" }
      expect(concepts.length).to eq(2)
      codes = concepts.map { |c| c["notation"] }
      expect(codes).to contain_exactly("200", "888")
    end

    it "includes language-mapped labels in member concepts" do
      concept_200 = jsonld["@graph"].find { |r| r["notation"] == "200" }
      expect(concept_200["prefLabel"]).to include("eng" => "geodetic latitude",
                                                  "deu" => "geodätische Breite")
    end
  end

  describe "vocabulary without title" do
    subject(:vocabulary) do
      described_class.new(id: "test", concepts: [concept_1])
    end

    it "still serializes to turtle" do
      expect(vocabulary.to_turtle).to include("skos:ConceptScheme")
    end

    it "still serializes to jsonld" do
      data = JSON.parse(vocabulary.to_jsonld)
      expect(data["@graph"].length).to be >= 2
    end
  end
end
