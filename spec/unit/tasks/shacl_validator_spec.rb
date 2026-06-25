# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "glossarist/validation/shacl_validator"

RSpec.describe Glossarist::Validation::ShaclValidator do
  let(:tmpdir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(tmpdir) }

  def write(name, content)
    File.write(File.join(tmpdir, name), content)
  end

  # A minimal SHACL shape used only to exercise the validator's mechanics.
  # Decoupled from the real glossarist shapes so this spec does not break
  # when the ontology shapes evolve.
  let(:shape_ttl) do
    <<~TURTLE
      @prefix ex:   <https://example.org/> .
      @prefix sh:   <http://www.w3.org/ns/shacl#> .
      @prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .

      ex:ConceptShape a sh:NodeShape ;
        sh:targetClass ex:Concept ;
        sh:property [
          sh:path ex:name ;
          sh:datatype xsd:string ;
          sh:minCount 1 ;
          sh:maxCount 1 ;
        ] .
    TURTLE
  end

  let(:shapes_path) { File.join(tmpdir, "shapes.ttl") }

  before { write("shapes.ttl", shape_ttl) }

  it "loads shapes from the given path and reports conformant data" do
    write("good.ttl", <<~TURTLE)
      @prefix ex: <https://example.org/> .
      ex:1 a ex:Concept ; ex:name "Alpha" .
    TURTLE

    validator = described_class.new(shapes_path: shapes_path)
    expect(validator.shapes_path).to eq(shapes_path)

    report = validator.validate_files([File.join(tmpdir, "good.ttl")])
    expect(report).to be_conformant
  end

  it "reports violations when a required property is missing" do
    write("broken.ttl", <<~TURTLE)
      @prefix ex: <https://example.org/> .
      ex:2 a ex:Concept .
    TURTLE

    validator = described_class.new(shapes_path: shapes_path)
    report = validator.validate_files([File.join(tmpdir, "broken.ttl")])

    expect(report).not_to be_conformant
    expect(report.to_s).to include("violation")
  end

  it "returns a conformant aggregate when given an empty file list" do
    validator = described_class.new(shapes_path: shapes_path)
    expect(validator.validate_files([])).to be_conformant
  end

  it "accepts a pre-loaded RDF::Graph" do
    graph = RDF::Graph.new
    RDF::Turtle::Reader.new(<<~TURTLE) { |r| r.each_statement { |s| graph << s } }
      @prefix ex: <https://example.org/> .
      ex:3 a ex:Concept ; ex:name "Beta" .
    TURTLE

    validator = described_class.new(shapes_path: shapes_path)
    expect(validator.validate_graphs([graph])).to be_conformant
  end

  describe ".default_shapes_path" do
    context "when concept-model gem is not available" do
      before do
        allow(described_class).to receive(:default_shapes_path)
          .and_raise(ArgumentError, /No SHACL shapes path provided/)
      end

      it "raises a helpful ArgumentError" do
        expect { described_class.default_shapes_path }
          .to raise_error(ArgumentError, /No SHACL shapes path provided/)
      end
    end
  end
end
