# frozen_string_literal: true

require "spec_helper"
require "lutaml/jsonld"
require "lutaml/turtle"
require "glossarist/rdf"

RSpec.describe Glossarist::Rdf::SkosConcept do
  let(:label_en) do
    Glossarist::Rdf::LocalizedLiteral.new(value: "component",
                                          language_code: "eng")
  end

  let(:label_fr) do
    Glossarist::Rdf::LocalizedLiteral.new(value: "composant",
                                          language_code: "fra")
  end

  let(:definition_en) do
    Glossarist::Rdf::LocalizedLiteral.new(
      value: "constituent part of a system", language_code: "eng",
    )
  end

  subject(:concept) do
    described_class.new(
      code: "2",
      labels: [label_en, label_fr],
      definitions: [definition_en],
      sources: ["ISO 19115-1:2014"],
      date_accepted: "2014-04-01",
      domain: "geotechnology",
    )
  end

  describe "attributes" do
    it "has a code" do
      expect(concept.code).to eq("2")
    end

    it "has labels as a collection" do
      expect(concept.labels.size).to eq(2)
    end

    it "has definitions as a collection" do
      expect(concept.definitions.size).to eq(1)
    end

    it "has sources as a collection" do
      expect(concept.sources).to include("ISO 19115-1:2014")
    end

    it "has a date_accepted" do
      expect(concept.date_accepted).to eq("2014-04-01")
    end

    it "has a domain" do
      expect(concept.domain).to eq("geotechnology")
    end
  end

  describe "rdf mappings" do
    it "has both turtle and jsonld mappings" do
      expect(described_class.mappings.keys).to include(:turtle, :jsonld)
    end

    it "has 8 predicate rules" do
      mapping = described_class.mappings[:turtle]
      expect(mapping.rdf_predicates.size).to eq(8)
    end

    it "has a subject block" do
      mapping = described_class.mappings[:turtle]
      expect(mapping.rdf_subject).to be_a(Proc)
    end

    it "has type set to skos:Concept" do
      mapping = described_class.mappings[:turtle]
      expect(mapping.rdf_type).to eq("skos:Concept")
    end
  end

  describe "#to_jsonld" do
    subject(:jsonld) { JSON.parse(concept.to_jsonld) }

    it "includes @context with namespace prefixes" do
      expect(jsonld["@context"]).to include("skos", "dcterms")
    end

    it "includes @type" do
      expect(jsonld["@type"]).to include("Concept")
    end

    it "includes @id with concept URI" do
      expect(jsonld["@id"]).to eq("https://glossarist.org/concept/2")
    end

    it "includes notation" do
      expect(jsonld["notation"]).to eq("2")
    end

    it "includes language-mapped prefLabels" do
      expect(jsonld["prefLabel"]).to include("eng" => "component",
                                             "fra" => "composant")
    end

    it "includes language-mapped definitions" do
      expect(jsonld["definition"]).to include("eng" => "constituent part of a system")
    end

    it "includes sources" do
      expect(jsonld["source"]).to include("ISO 19115-1:2014")
    end

    it "includes dateAccepted" do
      expect(jsonld["dateAccepted"]).to eq("2014-04-01")
    end

    it "includes subject (domain)" do
      expect(jsonld["subject"]).to eq("geotechnology")
    end
  end

  describe "#to_turtle" do
    subject(:turtle) { concept.to_turtle }

    it "includes prefix declarations" do
      expect(turtle).to include("@prefix skos:")
      expect(turtle).to include("@prefix dcterms:")
    end

    it "includes concept type" do
      expect(turtle).to include("a skos:Concept")
    end

    it "includes concept URI" do
      expect(turtle).to include("<https://glossarist.org/concept/2>")
    end

    it "includes notation" do
      expect(turtle).to include('skos:notation "2"')
    end

    it "includes language-tagged labels" do
      expect(turtle).to match(/"component"@eng/)
      expect(turtle).to match(/"composant"@fra/)
    end

    it "includes language-tagged definition" do
      expect(turtle).to match(/"constituent part of a system"@eng/)
    end

    it "includes source" do
      expect(turtle).to include('dcterms:source "ISO 19115-1:2014"')
    end

    it "includes dateAccepted" do
      expect(turtle).to include('dcterms:dateAccepted "2014-04-01"')
    end

    it "includes subject (domain)" do
      expect(turtle).to include('dcterms:subject "geotechnology"')
    end
  end
end
