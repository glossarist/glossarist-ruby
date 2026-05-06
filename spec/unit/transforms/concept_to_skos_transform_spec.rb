# frozen_string_literal: true

require "spec_helper"
require "lutaml/jsonld"
require "lutaml/turtle"
require "glossarist/transforms/concept_to_skos_transform"

RSpec.describe Glossarist::Transforms::ConceptToSkosTransform do
  let(:collection) do
    c = Glossarist::ManagedConceptCollection.new
    c.load_from_files(fixtures_path("concept_collection_v2"))
    c
  end

  let(:concept) do
    collection.find { |c| c.data.id == "2119" }
  end

  describe ".transform" do
    subject(:skos) { described_class.transform(concept) }

    it "returns a SkosConcept" do
      expect(skos).to be_a(Glossarist::Rdf::SkosConcept)
    end

    it "sets code from the concept identifier" do
      expect(skos.code).to eq("2119")
    end

    it "extracts preferred labels from localizations" do
      expect(skos.labels).not_to be_empty
      eng_label = skos.labels.find { |l| l.language_code == "eng" }
      expect(eng_label&.value).to eq("component")
    end

    it "extracts definitions from localizations" do
      expect(skos.definitions).not_to be_empty
      eng_def = skos.definitions.find { |d| d.language_code == "eng" }
      expect(eng_def&.value).to eq("constituent part of a postal address")
    end

    it "extracts alt labels from non-preferred terms" do
      expect(skos.alt_labels).not_to be_empty
      eng_alt = skos.alt_labels.find { |l| l.language_code == "eng" }
      expect(eng_alt&.value).to eq("postal address component")
    end

    it "extracts scope notes from localization notes" do
      eng_note = skos.scope_notes.find { |n| n.language_code == "eng" }
      expect(eng_note&.value).to eq("The components of postal addresses are defined in 6.2, 6.3 and 6.4.")
    end

    it "extracts authoritative sources" do
      expect(skos.sources).to include("ISO 19160-4:2017")
    end

    it "extracts domain from localization" do
      expect(skos.domain).to eq("postal address")
    end
  end

  describe ".transform_document" do
    let(:concepts) { collection.to_a }

    subject(:vocab) { described_class.transform_document(concepts) }

    it "returns a SkosVocabulary" do
      expect(vocab).to be_a(Glossarist::Rdf::SkosVocabulary)
    end

    it "sets id from options" do
      vocab = described_class.transform_document(concepts, shortname: "iso1087")
      expect(vocab.id).to eq("iso1087")
    end

    it "defaults id to 'glossary'" do
      expect(vocab.id).to eq("glossary")
    end

    it "maps all concepts to SkosConcept instances" do
      expect(vocab.concepts.length).to eq(4)
      vocab.concepts.each do |c|
        expect(c).to be_a(Glossarist::Rdf::SkosConcept)
      end
    end

    it "sets title from options" do
      vocab = described_class.transform_document(concepts, title: "My Glossary")
      expect(vocab.title).to eq("My Glossary")
    end
  end

  describe "integration: single concept to_jsonld" do
    subject(:jsonld) { concept.to_jsonld }

    it "produces valid JSON" do
      expect { JSON.parse(jsonld) }.not_to raise_error
    end

    it "includes @context with namespace prefixes" do
      parsed = JSON.parse(jsonld)
      expect(parsed["@context"]).to include("skos", "dcterms")
    end

    it "includes compact @type" do
      parsed = JSON.parse(jsonld)
      expect(parsed["@type"]).to eq("skos:Concept")
    end

    it "includes concept id in @id" do
      parsed = JSON.parse(jsonld)
      expect(parsed["@id"]).to include("2119")
    end

    it "includes notation" do
      parsed = JSON.parse(jsonld)
      expect(parsed["notation"]).to eq("2119")
    end

    it "includes language-mapped definitions" do
      parsed = JSON.parse(jsonld)
      expect(parsed["definition"]).to include("eng")
    end

    it "includes subject (domain)" do
      parsed = JSON.parse(jsonld)
      expect(parsed["subject"]).to eq("postal address")
    end
  end

  describe "integration: single concept to_turtle" do
    subject(:turtle) { concept.to_turtle }

    it "produces turtle with prefix declarations" do
      expect(turtle).to include("@prefix skos:")
      expect(turtle).to include("@prefix dcterms:")
    end

    it "includes the concept type" do
      expect(turtle).to include("a skos:Concept")
    end

    it "includes the concept URI" do
      expect(turtle).to include("glossarist.org/concept/2119")
    end

    it "includes language-tagged literals" do
      expect(turtle).to match(/"component"@eng/)
    end

    it "includes notation" do
      expect(turtle).to include('skos:notation "2119"')
    end

    it "includes source" do
      expect(turtle).to include("ISO 19160-4:2017")
    end

    it "includes subject (domain)" do
      expect(turtle).to include('dcterms:subject "postal address"')
    end
  end

  describe "integration: full document to_turtle" do
    let(:concepts) { collection.to_a }
    subject(:turtle) do
      described_class.transform_document(concepts).to_turtle
    end

    it "includes ConceptScheme" do
      expect(turtle).to include("a skos:ConceptScheme")
    end

    it "includes vocabulary URI" do
      expect(turtle).to include("glossarist.org/vocab/glossary")
    end

    it "includes all concepts" do
      expect(turtle.scan("a skos:Concept").length).to be >= 4
    end
  end

  describe "integration: full document to_jsonld" do
    let(:concepts) { collection.to_a }
    subject(:jsonld) do
      JSON.parse(described_class.transform_document(concepts).to_jsonld)
    end

    it "includes @graph" do
      expect(jsonld["@graph"]).to be_an(Array)
    end

    it "includes ConceptScheme" do
      scheme = jsonld["@graph"].find { |r| r["@type"] == "skos:ConceptScheme" }
      expect(scheme).not_to be_nil
    end

    it "includes all member concepts" do
      concepts_in_graph = jsonld["@graph"].select do |r|
        r["@type"] == "skos:Concept"
      end
      expect(concepts_in_graph.length).to be >= 4
    end
  end
end
