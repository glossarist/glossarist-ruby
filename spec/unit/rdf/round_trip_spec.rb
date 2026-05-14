# frozen_string_literal: true

require "spec_helper"
require "rdf/turtle"
require "glossarist/transforms/concept_to_gloss_transform"

module RoundTripConstants
  EXAMPLES_DIR = File.expand_path("../../../../concept-model/schemas/v2/examples", __dir__)
  GLOSS = Glossarist::Rdf::Namespaces::GlossaristNamespace.uri
  SKOS = Glossarist::Rdf::Namespaces::SkosNamespace.uri
  XL = Glossarist::Rdf::Namespaces::SkosxlNamespace.uri
  DCT = Glossarist::Rdf::Namespaces::DctermsNamespace.uri
  ISO = Glossarist::Rdf::Namespaces::IsoThesNamespace.uri
  RDF_NS = Glossarist::Rdf::Namespaces::RdfNamespace.uri
end

RSpec.describe "Round-trip: YAML → Ruby → Turtle → verify triples" do
  def parse_graph(turtle)
    g = RDF::Graph.new
    RDF::Turtle::Reader.new(turtle) { |r| r.each_statement { |s| g << s } }
    g
  end

  def gloss_ns
    RoundTripConstants::GLOSS
  end

  # ── Localized concept examples ────────────────────────────────────────

  describe "localized concept examples" do
    RoundTripConstants::EXAMPLES_DIR.then do |dir|
      Dir.glob(File.join(dir, "*.yaml")).sort.each do |path|
        basename = File.basename(path, ".yaml")
        data = YAML.safe_load(File.read(path), permitted_classes: [Date, Time])
        next unless data.is_a?(Hash) && data.dig("data", "language_code")

        it "#{basename} produces valid Turtle with at least one type triple" do
          lc = Glossarist::LocalizedConcept.of_yaml(data)
          mc = Glossarist::ManagedConcept.new(data: { id: basename })
          mc.add_l10n(lc)

          transform = Glossarist::Transforms::ConceptToGlossTransform.new(mc)
          turtle = transform.to_turtle
          expect(turtle).not_to be_empty

          graph = parse_graph(turtle)
          expect(graph.count).to be > 0
        end
      end
    end
  end

  # ── Managed concept examples ──────────────────────────────────────────

  describe "managed concept examples" do
    let(:minimal_l10n) do
      l = Glossarist::LocalizedConcept.new
      l.data.language_code = "eng"
      l.data.terms = [Glossarist::Designation::Expression.new(designation: "placeholder", type: "expression", normative_status: "preferred")]
      l
    end

    RoundTripConstants::EXAMPLES_DIR.then do |dir|
      Dir.glob(File.join(dir, "*.yaml")).sort.each do |path|
        basename = File.basename(path, ".yaml")
        data = YAML.safe_load(File.read(path), permitted_classes: [Date, Time])
        next unless data.is_a?(Hash) && (data.dig("data", "localized_concepts") || data.dig("data", "identifier"))

        it "#{basename} produces valid Turtle with gloss:Concept type" do
          mc = Glossarist::ManagedConcept.of_yaml(data)
          unless mc.localizations.any?
            mc.add_l10n(minimal_l10n)
          end

          transform = Glossarist::Transforms::ConceptToGlossTransform.new(mc)
          turtle = transform.to_turtle
          expect(turtle).not_to be_empty

          graph = parse_graph(turtle)
          concepts = graph.query([nil, RDF.type, RDF::URI("#{gloss_ns}Concept")])
          expect(concepts).not_to be_empty
        end
      end
    end
  end

  # ── Specific fixture-based round-trip verification ────────────────────

  describe "concept collection fixture" do
    let(:fixtures_dir) { fixtures_path("concept_collection_v2") }
    let(:collection) do
      c = Glossarist::ManagedConceptCollection.new
      c.load_from_files(fixtures_dir)
      c
    end

    it "every concept emits a valid Turtle document" do
      collection.each do |concept|
        transform = Glossarist::Transforms::ConceptToGlossTransform.new(concept)
        turtle = transform.to_turtle
        expect(turtle).not_to be_empty

        graph = parse_graph(turtle)
        expect(graph.query([nil, RDF.type, RDF::URI("#{gloss_ns}Concept")])).not_to be_empty
      end
    end

    it "every concept produces valid JSON-LD" do
      collection.each do |concept|
        jsonld = Glossarist::Transforms::ConceptToGlossTransform.new(concept).to_jsonld
        parsed = JSON.parse(jsonld)
        expect(parsed["@context"]).to be_a(Hash)
      end
    end

    it "document-level Turtle contains all concepts" do
      concepts = collection.to_a
      turtle = Glossarist::Transforms::ConceptToGlossTransform.transform_document(concepts)
      graph = parse_graph(turtle)

      concept_types = graph.query([nil, RDF.type, RDF::URI("#{gloss_ns}Concept")])
      expect(concept_types.count).to eq(concepts.length)
    end

    it "round-trip preserves concept identifiers" do
      collection.each do |concept|
        transform = Glossarist::Transforms::ConceptToGlossTransform.new(concept)
        turtle = transform.to_turtle
        graph = parse_graph(turtle)

        subj = graph.query([nil, RDF.type, RDF::URI("#{gloss_ns}Concept")]).first.subject
        id_stmts = graph.query([subj, RDF::URI("#{gloss_ns}identifier"), nil])
        expect(id_stmts.count).to eq(1)
        expected_id = concept.data&.id || concept.identifier
        expect(id_stmts.first.object.to_s).to eq(expected_id.to_s)
      end
    end

    it "round-trip preserves localization languages" do
      collection.each do |concept|
        next if concept.localizations.empty?

        transform = Glossarist::Transforms::ConceptToGlossTransform.new(concept)
        turtle = transform.to_turtle
        graph = parse_graph(turtle)

        l10n_subjects = graph.query([nil, RDF.type, RDF::URI("#{gloss_ns}LocalizedConcept")])
        expect(l10n_subjects.count).to eq(concept.localizations.size)
      end
    end

    it "round-trip preserves designation literal forms" do
      collection.each do |concept|
        concept.localizations.each_value do |l10n|
          next if l10n.designations.empty?

          transform = Glossarist::Transforms::ConceptToGlossTransform.new(concept)
          turtle = transform.to_turtle
          graph = parse_graph(turtle)

          literal_forms = graph.query([nil, RDF::URI("#{RoundTripConstants::XL}literalForm"), nil])
          expect(literal_forms.count).to be >= l10n.designations.size
        end
      end
    end
  end
end
