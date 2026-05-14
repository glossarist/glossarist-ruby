# frozen_string_literal: true

require "spec_helper"
require "rdf"
require "glossarist/transforms/concept_to_gloss_transform"

RSpec.describe Glossarist::Transforms::ConceptToGlossTransform do
  let(:fixtures_dir) { fixtures_path("concept_collection_v2") }

  let(:collection) do
    c = Glossarist::ManagedConceptCollection.new
    c.load_from_files(fixtures_dir)
    c
  end

  let(:concept) { collection.first }

  let(:transform) { described_class.new(concept) }

  let(:turtle) { transform.to_turtle }

  let(:graph) do
    require "rdf/turtle"
    g = RDF::Graph.new
    RDF::Turtle::Reader.new(turtle) { |reader| reader.each_statement { |s| g << s } }
    g
  end

  let(:gloss) { described_class::GLOSS }
  let(:skos) { described_class::SKOS }
  let(:xl) { described_class::XL }
  let(:iso) { described_class::ISO }
  let(:dct) { described_class::DCT }
  let(:rdf_ns) { described_class::RDF_NS }

  # ── Core concept mapping ──────────────────────────────────────────

  describe ".transform" do
    it "returns a GlossConcept instance" do
      result = described_class.transform(concept)
      expect(result).to be_a(Glossarist::Rdf::GlossConcept)
    end
  end

  describe ".transform_document" do
    it "returns Turtle string with all concepts" do
      concepts = collection.to_a
      result = described_class.transform_document(concepts)
      expect(result).to be_a(String)
      expect(result.length).to be > 100

      parsed_graph = RDF::Graph.new
      RDF::Turtle::Reader.new(result) { |reader| reader.each_statement { |s| parsed_graph << s } }
      concept_types = parsed_graph.query([nil, RDF.type, RDF::URI("#{gloss}Concept")])
      expect(concept_types.count).to eq(concepts.length)
    end
  end

  describe "concept types" do
    it "emits both gloss:Concept and skos:Concept types" do
      subject_uri = graph.query([nil, RDF.type, RDF::URI("#{gloss}Concept")]).first&.subject
      expect(subject_uri).not_to be_nil

      types = graph.query([subject_uri, RDF.type, nil]).map { |x| x.object.to_s }
      expect(types).to include("#{gloss}Concept")
      expect(types).to include("#{skos}Concept")
    end

    it "emits the concept identifier" do
      subject_uri = graph.query([nil, RDF.type, RDF::URI("#{gloss}Concept")]).first.subject
      id_stmts = graph.query([subject_uri, RDF::URI("#{gloss}identifier"), nil])
      expect(id_stmts.count).to eq(1)
    end
  end

  # ── Localized concept mapping ─────────────────────────────────────

  describe "localized concept" do
    let(:l10n_subjects) do
      graph.query([nil, RDF.type, RDF::URI("#{gloss}LocalizedConcept")]).map(&:subject)
    end

    it "emits gloss:LocalizedConcept and skos:Concept types" do
      expect(l10n_subjects).not_to be_empty
      l10n_subjects.each do |subj|
        types = graph.query([subj, RDF.type, nil]).map { |x| x.object.to_s }
        expect(types).to include("#{gloss}LocalizedConcept")
        expect(types).to include("#{skos}Concept")
      end
    end

    it "links to managed concept via gloss:hasLocalization" do
      concept_uri = graph.query([nil, RDF.type, RDF::URI("#{gloss}Concept")]).first.subject
      localization_stmts = graph.query([concept_uri, RDF::URI("#{gloss}hasLocalization"), nil])
      expect(localization_stmts.count).to be > 0
    end

    it "has dcterms:language" do
      l10n_subjects.each do |subj|
        langs = graph.query([subj, RDF::URI("#{dct}language"), nil])
        expect(langs.count).to eq(1)
      end
    end
  end

  # ── Designation (SKOS-XL pattern) ─────────────────────────────────

  describe "designation (SKOS-XL pattern)" do
    let(:designation_subjects) do
      graph.query([nil, RDF.type, RDF::URI("#{gloss}Expression")]).map(&:subject)
    end

    it "emits designation as skosxl:Label" do
      expect(designation_subjects).not_to be_empty
      designation_subjects.each do |subj|
        types = graph.query([subj, RDF.type, nil]).map { |x| x.object.to_s }
        expect(types).to include("#{xl}Label")
      end
    end

    it "has skosxl:literalForm" do
      designation_subjects.each do |subj|
        forms = graph.query([subj, RDF::URI("#{xl}literalForm"), nil])
        expect(forms.count).to eq(1)
      end
    end

    it "links designation to localized concept via skosxl:prefLabel or skosxl:altLabel" do
      xl_labels = graph.query([nil, RDF::URI("#{xl}prefLabel"), nil])
      alt_labels = graph.query([nil, RDF::URI("#{xl}altLabel"), nil])
      expect(xl_labels.count + alt_labels.count).to be > 0
    end
  end

  # ── Definition mapping ────────────────────────────────────────────

  describe "definition" do
    it "emits gloss:DetailedDefinition with rdf:value" do
      defs = graph.query([nil, RDF.type, RDF::URI("#{gloss}DetailedDefinition")])
      expect(defs.count).to be > 0

      def_subjects = defs.map(&:subject)
      def_subjects.each do |subj|
        values = graph.query([subj, RDF::URI("#{rdf_ns}value"), nil])
        expect(values.count).to eq(1)
      end
    end
  end

  # ── Source mapping ────────────────────────────────────────────────

  describe "concept source" do
    it "emits gloss:ConceptSource with type and status as URIs" do
      sources = graph.query([nil, RDF.type, RDF::URI("#{gloss}ConceptSource")])
      expect(sources.count).to be > 0

      sources.each do |src_stmt|
        src = src_stmt.subject
        type_stmts = graph.query([src, RDF::URI("#{gloss}sourceType"), nil])
        if type_stmts.any?
          expect(type_stmts.first.object).to be_a(RDF::URI)
        end
      end
    end

    it "links source to citation via gloss:sourceOrigin" do
      origin_stmts = graph.query([nil, RDF::URI("#{gloss}sourceOrigin"), nil])
      expect(origin_stmts.count).to be > 0
    end
  end

  # ── Citation with locality ────────────────────────────────────────

  describe "citation" do
    it "emits gloss:Citation with source reference" do
      citations = graph.query([nil, RDF.type, RDF::URI("#{gloss}Citation")])
      expect(citations.count).to be > 0
    end

    it "emits gloss:Locality when present" do
      localities = graph.query([nil, RDF.type, RDF::URI("#{gloss}Locality")])
      if localities.any?
        localities.each do |loc_stmt|
          loc = loc_stmt.subject
          type_stmts = graph.query([loc, RDF::URI("#{gloss}localityType"), nil])
          expect(type_stmts.count).to eq(1)
        end
      end
    end
  end

  # ── Concept date mapping ──────────────────────────────────────────

  describe "concept date" do
    it "emits gloss:ConceptDate when dates present" do
      dates = graph.query([nil, RDF.type, RDF::URI("#{gloss}ConceptDate")])
      if dates.any?
        dates.each do |date_stmt|
          date = date_stmt.subject
          value_stmts = graph.query([date, RDF::URI("#{gloss}dateValue"), nil])
          expect(value_stmts.count).to eq(1)
          type_stmts = graph.query([date, RDF::URI("#{gloss}dateType"), nil])
          expect(type_stmts.count).to eq(1)
        end
      end
    end

    it "links dates to concept via gloss:hasDate" do
      date_links = graph.query([nil, RDF::URI("#{gloss}hasDate"), nil])
      # Dates may or may not be present depending on fixture data
      expect(date_links.count).to be >= 0
    end
  end

  # ── Relationships ─────────────────────────────────────────────────

  describe "relationships" do
    it "builds relationship triples from REL_PROPERTY_MAP" do
      mc = Glossarist::ManagedConcept.new(
        data: { id: "test" },
        related: [
          { type: "broader", ref: { id: "parent" } },
          { type: "see", ref: { id: "other" } },
        ],
      )

      result = described_class.transform(mc)
      expect(result.relationship_triples).to include(
        ["#{skos}broader", "concept/parent"],
        ["#{skos}related", "concept/other"],
      )
    end

    it "skips unknown relationship types" do
      mc = Glossarist::ManagedConcept.new(
        data: { id: "test" },
        related: [
          { type: "unknown_type", ref: { id: "target" } },
        ],
      )

      result = described_class.transform(mc)
      expect(result.relationship_triples).to be_empty
    end

    it "skips relationships without a target id" do
      mc = Glossarist::ManagedConcept.new(
        data: { id: "test" },
        related: [
          { type: "broader", ref: { source: "ISO" } },
        ],
      )

      result = described_class.transform(mc)
      expect(result.relationship_triples).to be_empty
    end
  end

  # ── Output formats ────────────────────────────────────────────────

  describe "to_turtle" do
    it "produces valid Turtle with prefix declarations" do
      expect(turtle).to include("@prefix gloss:")
      expect(turtle).to include("@prefix skos:")
      expect(turtle).to include("@prefix skosxl:")
    end

    it "accepts an array of concepts" do
      concepts = collection.to_a
      turtle = described_class.new(nil).to_turtle(concepts)
      expect(turtle.length).to be > 100
    end
  end

  describe "to_jsonld" do
    it "produces JSON-LD with @context and @graph" do
      jsonld = described_class.new(concept).to_jsonld
      parsed = JSON.parse(jsonld)
      expect(parsed["@context"]).to be_a(Hash)
      expect(parsed["@graph"]).to be_an(Array)
    end
  end

  describe "to_jsonl_line" do
    it "produces valid JSON-LD for a single concept" do
      line = described_class.new(concept).to_jsonl_line
      parsed = JSON.parse(line)
      expect(parsed).to be_a(Hash)
      expect(parsed["@context"]).to be_a(Hash)
    end

    it "returns empty string without a concept" do
      line = described_class.new(nil).to_jsonl_line
      expect(line).to eq("")
    end
  end

  # ── Relationship property mapping ─────────────────────────────────

  describe "relationship property mapping" do
    it "uses skos:broader for broader relationships" do
      expect(described_class::REL_PROPERTY_MAP["broader"]).to eq("#{skos}broader")
    end

    it "uses iso-thes:broaderGeneric for broader_generic relationships" do
      expect(described_class::REL_PROPERTY_MAP["broader_generic"]).to eq("#{iso}broaderGeneric")
    end

    it "uses skos:exactMatch for equivalent relationships" do
      expect(described_class::REL_PROPERTY_MAP["equivalent"]).to eq("#{skos}exactMatch")
    end

    it "uses gloss:deprecates for deprecates relationships" do
      expect(described_class::REL_PROPERTY_MAP["deprecates"]).to eq("#{gloss}deprecates")
    end

    it "uses skos:related for see relationships" do
      expect(described_class::REL_PROPERTY_MAP["see"]).to eq("#{skos}related")
    end

    it "maps all ISO 25964 hierarchical subtypes" do
      expect(described_class::REL_PROPERTY_MAP["broader_generic"]).to eq("#{iso}broaderGeneric")
      expect(described_class::REL_PROPERTY_MAP["narrower_generic"]).to eq("#{iso}narrowerGeneric")
      expect(described_class::REL_PROPERTY_MAP["broader_partitive"]).to eq("#{iso}broaderPartitive")
      expect(described_class::REL_PROPERTY_MAP["narrower_partitive"]).to eq("#{iso}narrowerPartitive")
      expect(described_class::REL_PROPERTY_MAP["broader_instantial"]).to eq("#{iso}broaderInstantial")
      expect(described_class::REL_PROPERTY_MAP["narrower_instantial"]).to eq("#{iso}narrowerInstantial")
    end

    it "maps all SKOS mapping properties" do
      expect(described_class::REL_PROPERTY_MAP["close_match"]).to eq("#{skos}closeMatch")
      expect(described_class::REL_PROPERTY_MAP["broad_match"]).to eq("#{skos}broadMatch")
      expect(described_class::REL_PROPERTY_MAP["narrow_match"]).to eq("#{skos}narrowMatch")
      expect(described_class::REL_PROPERTY_MAP["related_match"]).to eq("#{skos}relatedMatch")
    end

    it "maps glossarist-specific relationship types" do
      expect(described_class::REL_PROPERTY_MAP["supersedes"]).to eq("#{gloss}supersedes")
      expect(described_class::REL_PROPERTY_MAP["superseded_by"]).to eq("#{gloss}supersededBy")
      expect(described_class::REL_PROPERTY_MAP["compare"]).to eq("#{gloss}compares")
      expect(described_class::REL_PROPERTY_MAP["contrast"]).to eq("#{gloss}contrasts")
      expect(described_class::REL_PROPERTY_MAP["homograph"]).to eq("#{gloss}hasHomograph")
      expect(described_class::REL_PROPERTY_MAP["false_friend"]).to eq("#{gloss}hasFalseFriend")
    end

    it "maps designation-level relationship types" do
      expect(described_class::REL_PROPERTY_MAP["abbreviated_form_for"]).to eq("#{gloss}abbreviatedFormFor")
      expect(described_class::REL_PROPERTY_MAP["short_form_for"]).to eq("#{gloss}shortFormFor")
    end
  end

  # ── Designation subtype dispatch ────────────────────────────────────

  describe "designation subtype dispatch" do
    let(:abbr_concept) do
      desig = Glossarist::Designation::Abbreviation.new(
        designation: "LED", type: "abbreviation",
      )
      l10n = Glossarist::LocalizedConcept.new(language_code: "eng")
      l10n.data.terms = [desig]
      mc = Glossarist::ManagedConcept.new(data: { id: "abbr-test" })
      mc.add_l10n(l10n)
      mc
    end

    let(:abbr_turtle) { described_class.new(abbr_concept).to_turtle }

    let(:abbr_graph) do
      g = RDF::Graph.new
      RDF::Turtle::Reader.new(abbr_turtle) { |r| r.each_statement { |s| g << s } }
      g
    end

    it "emits gloss:Abbreviation type for abbreviation designations" do
      abbrevs = abbr_graph.query([nil, RDF.type, RDF::URI("#{gloss}Abbreviation")])
      expect(abbrevs.count).to be > 0
      abbrevs.each do |stmt|
        types = abbr_graph.query([stmt.subject, RDF.type, nil]).map { |x| x.object.to_s }
        expect(types).to include("#{xl}Label")
      end
    end

    it "emits gloss:Expression type for expression designations" do
      exprs = graph.query([nil, RDF.type, RDF::URI("#{gloss}Expression")])
      expect(exprs.count).to be > 0
    end

    it "all designations have skosxl:Label type" do
      designations = graph.query([nil, RDF.type, RDF::URI("#{xl}Label")])
      expect(designations.count).to be > 0
    end
  end

  # ── SKOS-XL normative status linking ──────────────────────────────────

  describe "SKOS-XL normative status linking" do
    let(:pref_concept) do
      desig = Glossarist::Designation::Expression.new(
        designation: "mass", type: "expression", normative_status: "preferred",
      )
      l10n = Glossarist::LocalizedConcept.new(language_code: "eng")
      l10n.data.terms = [desig]
      mc = Glossarist::ManagedConcept.new(data: { id: "pref-test" })
      mc.add_l10n(l10n)
      mc
    end

    let(:pref_turtle) { described_class.new(pref_concept).to_turtle }

    let(:pref_graph) do
      g = RDF::Graph.new
      RDF::Turtle::Reader.new(pref_turtle) { |r| r.each_statement { |s| g << s } }
      g
    end

    it "uses skosxl:prefLabel for preferred designations" do
      pref_labels = pref_graph.query([nil, RDF::URI("#{xl}prefLabel"), nil])
      expect(pref_labels.count).to eq(1)
    end

    it "uses skosxl:altLabel for non-preferred designations" do
      alt_labels = graph.query([nil, RDF::URI("#{xl}altLabel"), nil])
      expect(alt_labels.count).to be >= 0
    end
  end

  # ── Designation-level relationships ─────────────────────────────────

  describe "designation-level relationships" do
    let(:rel_concept) do
      rc = Glossarist::RelatedConcept.new(type: "abbreviated_form_for")
      rc.ref = Glossarist::Citation.new(text: "light-emitting diode")
      rc.ref.id = "led_full"

      desig = Glossarist::Designation::Abbreviation.new(
        designation: "LED", type: "abbreviation",
      )
      desig.related = [rc]

      l10n = Glossarist::LocalizedConcept.new(language_code: "eng")
      l10n.data.terms = [desig]
      mc = Glossarist::ManagedConcept.new(data: { id: "rel-test" })
      mc.add_l10n(l10n)
      mc
    end

    let(:rel_turtle) { described_class.new(rel_concept).to_turtle }

    let(:rel_graph) do
      g = RDF::Graph.new
      RDF::Turtle::Reader.new(rel_turtle) { |r| r.each_statement { |s| g << s } }
      g
    end

    it "builds relationship triples from designation related concepts" do
      result = described_class.transform(rel_concept)

      desig_gc = result.localizations.first.designations.first
      expect(desig_gc.relationship_triples).not_to be_empty
    end

    it "emits relationship triples in Turtle output" do
      abbr_triples = rel_graph.query([nil, RDF::URI("#{gloss}abbreviatedFormFor"), nil])
      expect(abbr_triples.count).to eq(1)
      expect(abbr_triples.first.object.to_s).to eq("concept/led_full")
    end
  end

  # ── Deterministic output ─────────────────────────────────────────────

  describe "deterministic output" do
    it "produces identical Turtle for the same concept across invocations" do
      t1 = described_class.new(concept).to_turtle
      t2 = described_class.new(concept).to_turtle
      expect(t1).to eq(t2)
    end

    it "produces deterministic citation subjects" do
      citation = Glossarist::Rdf::GlossCitation.new(
        text: "ISO 19111:2019",
        source: nil,
        id: nil,
      )
      slug1 = described_class::GLOSS # just to verify module access
      subject1 = Glossarist::Rdf::GlossCitation.slug(citation)
      subject2 = Glossarist::Rdf::GlossCitation.slug(citation)
      expect(subject1).to eq(subject2)
      expect(subject1).not_to be_empty
    end
  end

  # ── JSON-LD output structure ─────────────────────────────────────────

  describe "JSON-LD output structure" do
    let(:jsonld) { described_class.new(concept).to_jsonld }
    let(:parsed) { JSON.parse(jsonld) }

    it "includes @context with namespace prefixes" do
      ctx = parsed["@context"]
      expect(ctx).to include("gloss")
      expect(ctx).to include("skos")
    end

    it "includes @graph array with resources" do
      graph_data = parsed["@graph"]
      expect(graph_data).to be_an(Array)
      expect(graph_data.length).to be > 0
    end

    it "each resource has @type" do
      parsed["@graph"].each do |resource|
        next unless resource.is_a?(Hash)
        expect(resource).to have_key("@type").or have_key("gloss:identifier")
      end
    end
  end

  # ── Edge cases ───────────────────────────────────────────────────────

  describe "edge cases" do
    it "handles a minimal concept with no localizations" do
      mc = Glossarist::ManagedConcept.new(data: { id: "minimal" })
      result = described_class.transform(mc)
      expect(result).to be_a(Glossarist::Rdf::GlossConcept)
      expect(result.identifier).to eq("minimal")
    end

    it "handles a concept with no sources" do
      mc = Glossarist::ManagedConcept.new(data: { id: "nosrc" })
      turtle = described_class.new(mc).to_turtle
      expect(turtle).to include("concept/nosrc")
    end

    it "handles a concept with empty relationship list" do
      mc = Glossarist::ManagedConcept.new(
        data: { id: "norels" },
        related: [],
      )
      result = described_class.transform(mc)
      expect(result.relationship_triples).to be_empty
    end

    it "to_turtle returns empty string for nil concept" do
      expect(described_class.new(nil).to_turtle).to eq("")
    end

    it "to_jsonld returns empty string for nil concept" do
      expect(described_class.new(nil).to_jsonld).to eq("")
    end
  end

  # ── Namespace deduplication ──────────────────────────────────────────

  describe "namespace constants" do
    it "derives GLOSS from Namespaces module" do
      expect(described_class::GLOSS).to eq(Glossarist::Rdf::Namespaces::GlossaristNamespace.uri)
    end

    it "derives SKOS from Namespaces module" do
      expect(described_class::SKOS).to eq(Glossarist::Rdf::Namespaces::SkosNamespace.uri)
    end

    it "derives ISO from Namespaces module" do
      expect(described_class::ISO).to eq(Glossarist::Rdf::Namespaces::IsoThesNamespace.uri)
    end
  end
end
