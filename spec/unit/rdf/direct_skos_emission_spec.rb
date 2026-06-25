# frozen_string_literal: true

require "spec_helper"
require "rdf/turtle"
require "glossarist/transforms/concept_to_gloss_transform"

RSpec.describe "Direct SKOS emission (B6)" do
  let(:fixtures_dir) { fixtures_path("concept_collection_v2") }

  def concept
    collection = Glossarist::ManagedConceptCollection.new
    collection.load_from_files(fixtures_dir)
    collection.first
  end

  def turtle
    transform = Glossarist::Transforms::ConceptToGlossTransform.new(concept)
    transform.to_turtle
  end

  def graph
    g = RDF::Graph.new
    RDF::Turtle::Reader.new(turtle) { |r| r.each_statement { |s| g << s } }
    g
  end

  let(:skos) { "http://www.w3.org/2004/02/skos/core#" }

  it "emits skos:prefLabel / altLabel / hiddenLabel as direct literals" do
    label_preds = [
      RDF::URI("#{skos}prefLabel"),
      RDF::URI("#{skos}altLabel"),
      RDF::URI("#{skos}hiddenLabel"),
    ]
    direct = graph.query([nil, nil, nil]).select do |stmt|
      label_preds.include?(stmt.predicate) && stmt.object.is_a?(RDF::Literal)
    end
    expect(direct).not_to be_empty
  end

  it "tags direct SKOS labels with the concept language" do
    literals = graph.query([nil, RDF::URI("#{skos}altLabel"), nil])
                     .select { |s| s.object.is_a?(RDF::Literal) }
    expect(literals).not_to be_empty
    expect(literals.map { |s| s.object.language }.uniq).to include(:eng)
  end

  it "emits skos:definition as a direct literal for each definition" do
    defs = graph.query([nil, RDF::URI("#{skos}definition"), nil])
                 .select { |s| s.object.is_a?(RDF::Literal) }
    expect(defs).not_to be_empty
  end

  it "emits skos:example / skos:scopeNote as direct literals" do
    examples = graph.query([nil, RDF::URI("#{skos}example"), nil])
                     .select { |s| s.object.is_a?(RDF::Literal) }
    notes = graph.query([nil, RDF::URI("#{skos}scopeNote"), nil])
                 .select { |s| s.object.is_a?(RDF::Literal) }
    expect(examples.length + notes.length).to be > 0
  end

  it "still emits the reified skosxl:Label nodes" do
    skosxl_labels = graph.query([nil, RDF.type,
                                 RDF::URI("http://www.w3.org/2008/05/skos-xl#Label")])
    expect(skosxl_labels).not_to be_empty
  end
end
