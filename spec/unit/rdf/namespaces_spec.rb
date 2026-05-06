# frozen_string_literal: true

require "spec_helper"
require "lutaml/jsonld"
require "lutaml/turtle"
require "glossarist/rdf"

RSpec.describe Glossarist::Rdf::Namespaces do
  describe "SkosNamespace" do
    subject(:ns) { described_class::SkosNamespace }

    it "has the SKOS URI" do
      expect(ns.uri.to_s).to eq("http://www.w3.org/2004/02/skos/core#")
    end

    it "has the skos prefix" do
      expect(ns.prefix).to eq("skos")
    end

    it "resolves predicate URIs" do
      expect(ns["prefLabel"]).to eq("http://www.w3.org/2004/02/skos/core#prefLabel")
    end
  end

  describe "DctermsNamespace" do
    subject(:ns) { described_class::DctermsNamespace }

    it "has the DCTERMS URI" do
      expect(ns.uri.to_s).to eq("http://purl.org/dc/terms/")
    end

    it "has the dcterms prefix" do
      expect(ns.prefix).to eq("dcterms")
    end

    it "resolves predicate URIs" do
      expect(ns["source"]).to eq("http://purl.org/dc/terms/source")
    end
  end
end
