# frozen_string_literal: true

require "spec_helper"
require "glossarist/transforms/concept_to_tbx_transform"

RSpec.describe Glossarist::Transforms::ConceptToTbxTransform do
  let(:collection) do
    c = Glossarist::ManagedConceptCollection.new
    c.load_from_files(fixtures_path("concept_collection_v2"))
    c
  end

  let(:concept) do
    collection.find { |c| c.data.id == "2119" }
  end

  describe ".transform" do
    subject(:entry) { described_class.transform(concept) }

    it "returns a Tbx::ConceptEntry" do
      expect(entry).to be_a(Tbx::ConceptEntry)
    end

    it "sets the entry id" do
      expect(entry.id).to eq("2119")
    end

    it "includes language sections" do
      expect(entry.lang_sec).not_to be_empty
    end

    it "prefixes id with shortname" do
      entry = described_class.transform(concept, shortname: "iso1087")
      expect(entry.id).to eq("iso1087_2119")
    end
  end

  describe ".transform_document" do
    let(:concepts) { collection.to_a }

    subject(:doc) { described_class.transform_document(concepts) }

    it "returns a Tbx::Document" do
      expect(doc).to be_a(Tbx::Document)
    end

    it "includes all concepts as entries" do
      entries = doc.text.body.concept_entry
      expect(entries.length).to eq(4)
    end

    it "sets title when provided" do
      doc = described_class.transform_document(concepts, title: "Test Glossary")
      expect(doc.tbx_header).not_to be_nil
    end

    it "produces valid XML" do
      xml = doc.to_xml
      expect(xml).to include("<tbx")
      expect(xml).to include("</tbx>")
    end
  end
end
