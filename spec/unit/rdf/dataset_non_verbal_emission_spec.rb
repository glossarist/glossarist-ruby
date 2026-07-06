# frozen_string_literal: true

require "spec_helper"
require "rdf/turtle"
require "glossarist/transforms/concept_to_gloss_transform"

RSpec.describe "Dataset-level non-verbal entity RDF emission (K1)" do
  let(:transform) { Glossarist::Transforms::ConceptToGlossTransform }
  let(:gloss_uri) { Glossarist::Rdf::Namespaces::GlossaristNamespace.uri }
  let(:dcterms_uri) { Glossarist::Rdf::Namespaces::DctermsNamespace.uri }

  def parse_graph(turtle)
    graph = RDF::Graph.new
    RDF::Turtle::Reader.new(turtle) { |r| r.each_statement { |s| graph << s } }
    graph
  end

  describe "GlossFigure emission" do
    let(:figure) do
      Glossarist::Figure.new(
        id: "fig-mixed-reflection",
        identifier: "Figure 7c",
        caption: { "eng" => "Mixed reflection", "fra" => "Réflexion mixte" },
        description: { "eng" => "Diagram showing mixed reflection." },
      ).tap do |f|
        f.images = [
          Glossarist::FigureImage.new(src: "mixed-reflection.svg", format: "svg",
                                      role: "vector"),
          Glossarist::FigureImage.new(src: "mixed-reflection.png", format: "png",
                                      role: "raster"),
        ]
      end
    end

    it "emits a gloss:Figure subject keyed by figure id" do
      turtle = transform.transform_document([], figures: [figure])
      graph = parse_graph(turtle)
      subjects = graph.subjects.map(&:to_s)
      expect(subjects).to include("figure/fig-mixed-reflection")
    end

    it "emits the first image variant as gloss:image (xsd:anyURI)" do
      turtle = transform.transform_document([], figures: [figure])
      graph = parse_graph(turtle)
      image_stmts = graph.query([nil, RDF::URI("#{gloss_uri}image"), nil])
      expect(image_stmts.first.object.to_s).to eq("mixed-reflection.svg")
    end

    it "picks the eng caption when present (K1 FigureShape: single string)" do
      turtle = transform.transform_document([], figures: [figure])
      graph = parse_graph(turtle)
      caption_stmts = graph.query([nil, RDF::URI("#{gloss_uri}caption"), nil])
      expect(caption_stmts.first.object.to_s).to eq("Mixed reflection")
    end

    it "emits dcterms:description from the localized description hash" do
      turtle = transform.transform_document([], figures: [figure])
      graph = parse_graph(turtle)
      desc_stmts = graph.query([nil, RDF::URI("#{dcterms_uri}description"), nil])
      expect(desc_stmts.first.object.to_s).to eq("Diagram showing mixed reflection.")
    end

    it "falls back to the first available language when eng is absent" do
      figure.caption = { "deu" => "Mischreflexion" }
      turtle = transform.transform_document([], figures: [figure])
      graph = parse_graph(turtle)
      caption = graph.query([nil, RDF::URI("#{gloss_uri}caption"), nil])
      expect(caption.first.object.to_s).to eq("Mischreflexion")
    end
  end

  describe "GlossTable emission" do
    let(:table) do
      Glossarist::Table.new(
        id: "tbl-si-base-units",
        identifier: "Table 2",
        caption: { "eng" => "SI base units" },
        content: { "headers" => %w[Unit Symbol], "rows" => [%w[metre m]] },
        format: "structured",
      )
    end

    it "emits a gloss:Table subject keyed by table id" do
      turtle = transform.transform_document([], tables: [table])
      graph = parse_graph(turtle)
      expect(graph.subjects.map(&:to_s)).to include("table/tbl-si-base-units")
    end

    it "emits gloss:content with serialized table content" do
      turtle = transform.transform_document([], tables: [table])
      graph = parse_graph(turtle)
      content = graph.query([nil, RDF::URI("#{gloss_uri}content"), nil])
      expect(content.first.object.to_s).to include("metre")
    end

    it "emits dcterms:title from the table identifier" do
      turtle = transform.transform_document([], tables: [table])
      graph = parse_graph(turtle)
      title = graph.query([nil, RDF::URI("#{dcterms_uri}title"), nil])
      expect(title.first.object.to_s).to eq("Table 2")
    end
  end

  describe "GlossFormula emission" do
    let(:formula) do
      Glossarist::Formula.new(
        id: "fml-wave-eq",
        identifier: "Equation 1",
        expression: { "eng" => "\\nabla^2 E = 0" },
        notation: "latex",
        description: { "eng" => "Electromagnetic wave equation." },
      )
    end

    it "emits a gloss:Formula subject keyed by formula id" do
      turtle = transform.transform_document([], formulas: [formula])
      graph = parse_graph(turtle)
      expect(graph.subjects.map(&:to_s)).to include("formula/fml-wave-eq")
    end

    it "emits gloss:expression with the localized expression picked" do
      turtle = transform.transform_document([], formulas: [formula])
      graph = parse_graph(turtle)
      expr = graph.query([nil, RDF::URI("#{gloss_uri}expression"), nil])
      expect(expr.first.object.to_s).to include("nabla")
    end

    it "emits gloss:latexForm when notation is latex" do
      turtle = transform.transform_document([], formulas: [formula])
      graph = parse_graph(turtle)
      latex = graph.query([nil, RDF::URI("#{gloss_uri}latexForm"), nil])
      expect(latex.first.object.to_s).to include("nabla")
    end

    it "omits gloss:latexForm when notation is not latex" do
      formula.notation = "mathml"
      turtle = transform.transform_document([], formulas: [formula])
      graph = parse_graph(turtle)
      latex = graph.query([nil, RDF::URI("#{gloss_uri}latexForm"), nil])
      expect(latex).to be_empty
    end
  end

  describe "build_document backward compatibility" do
    it "accepts concepts only (pre-existing signature) without raising" do
      expect { transform.transform_document([]) }.not_to raise_error
    end
  end
end
