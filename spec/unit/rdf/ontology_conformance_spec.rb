# frozen_string_literal: true

require "spec_helper"
require "rdf/turtle"
require "glossarist/transforms/concept_to_gloss_transform"

RSpec.describe "RDF output conformance to glossarist ontology" do
  let(:gloss_ns) { Glossarist::Rdf::Namespaces::GlossaristNamespace.uri }
  let(:skos_ns) { "http://www.w3.org/2004/02/skos/core#" }
  let(:xl_ns) { "http://www.w3.org/2008/05/skos-xl#" }
  let(:dct_ns) { "http://purl.org/dc/terms/" }

  def parse_graph(turtle)
    g = RDF::Graph.new
    RDF::Turtle::Reader.new(turtle) { |r| r.each_statement { |s| g << s } }
    g
  end

  def concept_graph
    collection = Glossarist::ManagedConceptCollection.new
    collection.load_from_files(fixtures_path("concept_collection_v2"))
    concept = collection.first
    transform = Glossarist::Transforms::ConceptToGlossTransform.new(concept)
    parse_graph(transform.to_turtle)
  end

  describe "Concept node" do
    let(:graph) { concept_graph }
    let(:concept_node) { graph.query([nil, RDF.type, RDF::URI("#{gloss_ns}Concept")]).first.subject }

    it "has gloss:Concept type" do
      expect(graph.query([concept_node, RDF.type, RDF::URI("#{gloss_ns}Concept")])).not_to be_empty
    end

    it "has skos:Concept type" do
      expect(graph.query([concept_node, RDF.type, RDF::URI("#{skos_ns}Concept")])).not_to be_empty
    end

    it "has gloss:identifier" do
      id_stmts = graph.query([concept_node, RDF::URI("#{gloss_ns}identifier"), nil])
      expect(id_stmts).not_to be_empty
      expect(id_stmts.first.object).to be_a(RDF::Literal)
    end

    it "has gloss:hasLocalization targeting gloss:LocalizedConcept" do
      l10n_stmts = graph.query([concept_node, RDF::URI("#{gloss_ns}hasLocalization"), nil])
      l10n_stmts.each do |stmt|
        expect(graph.query([stmt.object, RDF.type, RDF::URI("#{gloss_ns}LocalizedConcept")])).not_to be_empty
      end
    end
  end

  describe "LocalizedConcept node" do
    let(:graph) { concept_graph }
    let(:l10n_node) { graph.query([nil, RDF.type, RDF::URI("#{gloss_ns}LocalizedConcept")]).first.subject }

    it "has dcterms:language" do
      lang_stmts = graph.query([l10n_node, RDF::URI("#{dct_ns}language"), nil])
      expect(lang_stmts).not_to be_empty
    end

    it "is connected to Concept via gloss:hasLocalization" do
      concept_node = graph.query([nil, RDF.type, RDF::URI("#{gloss_ns}Concept")]).first.subject
      l10n_stmts = graph.query([concept_node, RDF::URI("#{gloss_ns}hasLocalization"), l10n_node])
      expect(l10n_stmts).not_to be_empty
    end
  end

  describe "Designation node" do
    let(:graph) { concept_graph }
    let(:desig_nodes) { graph.query([nil, RDF::URI("#{xl_ns}literalForm"), nil]).map(&:subject) }

    it "every designation has a literalForm" do
      expect(desig_nodes).not_to be_empty
    end

    it "every designation is typed as a glossarist designation class" do
      desig_nodes.each do |node|
        types = graph.query([node, RDF.type, nil]).map { |s| s.object.to_s }
        designation_types = types.select { |t| t.start_with?(gloss_ns) && !t.include?("Concept") }
        expect(designation_types).not_to be_empty, "Node #{node} has no glossarist designation type. Types: #{types}"
      end
    end
  end

  describe "source node" do
    let(:graph) { concept_graph }
    let(:source_nodes) { graph.query([nil, RDF.type, RDF::URI("#{gloss_ns}ConceptSource")]).map(&:subject) }

    it "has gloss:ConceptSource type" do
      expect(source_nodes).not_to be_empty
    end

    it "has gloss:sourceType" do
      source_nodes.each do |node|
        type_stmts = graph.query([node, RDF::URI("#{gloss_ns}sourceType"), nil])
        expect(type_stmts).not_to be_empty, "ConceptSource #{node} missing gloss:sourceType"
      end
    end
  end

  describe "v3 example round-trip" do
    v3_dir = File.expand_path("../../fixtures/concept-model-examples/v3", __dir__)

    Dir.glob(File.join(v3_dir, "*.yaml")).sort.each do |path|
      basename = File.basename(path, ".yaml")
      data = YAML.safe_load(File.read(path), permitted_classes: [Date, Time])
      next unless data.is_a?(Hash) && data.dig("data", "language_code")

      it "#{basename}: designations produce gloss:Designation subclass types" do
        lc = Glossarist::LocalizedConcept.of_yaml(data)
        mc = Glossarist::ManagedConcept.new(data: { id: basename })
        mc.add_l10n(lc)

        graph = parse_graph(Glossarist::Transforms::ConceptToGlossTransform.new(mc).to_turtle)
        desig_types = graph.query([nil, RDF.type, nil])
          .map { |s| s.object.to_s }
          .select { |t| t.start_with?(gloss_ns) && !t.end_with?("Concept") }
        expect(desig_types).not_to be_empty
      end
    end
  end
end
