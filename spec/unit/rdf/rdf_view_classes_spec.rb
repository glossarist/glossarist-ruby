# frozen_string_literal: true

require "spec_helper"
require "rdf/turtle"

RSpec.shared_context "rdf graph helpers" do
  let(:gloss) { Glossarist::Rdf::Namespaces::GlossaristNamespace.uri }
  let(:skos) { Glossarist::Rdf::Namespaces::SkosNamespace.uri }
  let(:xl) { Glossarist::Rdf::Namespaces::SkosxlNamespace.uri }
  let(:dct) { Glossarist::Rdf::Namespaces::DctermsNamespace.uri }
  let(:iso) { Glossarist::Rdf::Namespaces::IsoThesNamespace.uri }
  let(:rdf_ns) { Glossarist::Rdf::Namespaces::RdfNamespace.uri }

  def parse_turtle(turtle)
    g = RDF::Graph.new
    RDF::Turtle::Reader.new(turtle) { |r| r.each_statement { |s| g << s } }
    g
  end
end

# ── GlossLocality ────────────────────────────────────────────────────────

RSpec.describe Glossarist::Rdf::GlossLocality do
  include_context "rdf graph helpers"

  it "emits gloss:Locality type" do
    loc = described_class.new(locality_type: "clause", reference_from: "3.1")
    graph = parse_turtle(described_class.to_turtle(loc))
    types = graph.query([nil, RDF.type, RDF::URI("#{gloss}Locality")])
    expect(types).not_to be_empty
  end

  it "emits locality predicates" do
    loc = described_class.new(locality_type: "page", reference_from: "42", reference_to: "47")
    graph = parse_turtle(described_class.to_turtle(loc))
    subj = graph.query([nil, RDF.type, RDF::URI("#{gloss}Locality")]).first.subject
    expect(graph.query([subj, RDF::URI("#{gloss}localityType"), nil]).first.object.to_s).to eq("page")
    expect(graph.query([subj, RDF::URI("#{gloss}referenceFrom"), nil]).first.object.to_s).to eq("42")
    expect(graph.query([subj, RDF::URI("#{gloss}referenceTo"), nil]).first.object.to_s).to eq("47")
  end

  it "generates deterministic subject URI" do
    loc = described_class.new(locality_type: "section", reference_from: "5")
    s1 = described_class.to_turtle(loc)
    s2 = described_class.to_turtle(loc)
    expect(s1).to eq(s2)
  end
end

# ── GlossCitation ────────────────────────────────────────────────────────

RSpec.describe Glossarist::Rdf::GlossCitation do
  include_context "rdf graph helpers"

  it "emits gloss:Citation type" do
    cit = described_class.new(text: "ISO 9001:2015", source: "ISO", id: "9001")
    graph = parse_turtle(described_class.to_turtle(cit))
    types = graph.query([nil, RDF.type, RDF::URI("#{gloss}Citation")])
    expect(types).not_to be_empty
  end

  it "emits citation predicates" do
    cit = described_class.new(source: "IEC", id: "60050-102", version: "2007", link: "https://example.org")
    graph = parse_turtle(described_class.to_turtle(cit))
    subj = graph.query([nil, RDF.type, RDF::URI("#{gloss}Citation")]).first.subject
    expect(graph.query([subj, RDF::URI("#{gloss}citationSource"), nil]).first.object.to_s).to eq("IEC")
    expect(graph.query([subj, RDF::URI("#{gloss}citationId"), nil]).first.object.to_s).to eq("60050-102")
    expect(graph.query([subj, RDF::URI("#{gloss}citationVersion"), nil]).first.object.to_s).to eq("2007")
  end

  it "uses slug from source/id for subject" do
    cit = described_class.new(source: "ISO", id: "10241-1")
    slug = described_class.slug(cit)
    expect(slug).to eq("ISO/10241-1")
  end

  it "falls back to MD5 hash when source and id are empty" do
    cit = described_class.new(text: "Some citation text")
    slug = described_class.slug(cit)
    expect(slug).to match(/^[0-9a-f]{12}$/)
  end

  it "emits locality when present" do
    loc = Glossarist::Rdf::GlossLocality.new(locality_type: "clause", reference_from: "3.1")
    cit = described_class.new(source: "ISO", id: "9001", locality: loc)
    graph = parse_turtle(described_class.to_turtle(cit))
    localities = graph.query([nil, RDF.type, RDF::URI("#{gloss}Locality")])
    expect(localities).not_to be_empty
  end
end

# ── GlossConceptSource ───────────────────────────────────────────────────

RSpec.describe Glossarist::Rdf::GlossConceptSource do
  include_context "rdf graph helpers"

  it "emits gloss:ConceptSource type" do
    src = described_class.new(status: "gloss:srcstatus/identical", type: "gloss:srctype/authoritative")
    graph = parse_turtle(described_class.to_turtle(src))
    types = graph.query([nil, RDF.type, RDF::URI("#{gloss}ConceptSource")])
    expect(types).not_to be_empty
  end

  it "emits source status and type as URIs" do
    src = described_class.new(status: "gloss:srcstatus/modified", type: "gloss:srctype/authoritative")
    graph = parse_turtle(described_class.to_turtle(src))
    subj = graph.query([nil, RDF.type, RDF::URI("#{gloss}ConceptSource")]).first.subject
    status_stmt = graph.query([subj, RDF::URI("#{gloss}sourceStatus"), nil]).first
    expect(status_stmt.object).to be_a(RDF::URI)
    type_stmt = graph.query([subj, RDF::URI("#{gloss}sourceType"), nil]).first
    expect(type_stmt.object).to be_a(RDF::URI)
  end

  it "generates deterministic ID from attributes" do
    src1 = described_class.new(status: "identical", type: "authoritative", modification: nil)
    src2 = described_class.new(status: "identical", type: "authoritative", modification: nil)
    expect(described_class.deterministic_id(src1)).to eq(described_class.deterministic_id(src2))
  end

  it "produces different IDs for different attributes" do
    src1 = described_class.new(status: "identical", type: "authoritative")
    src2 = described_class.new(status: "modified", type: "authoritative")
    expect(described_class.deterministic_id(src1)).not_to eq(described_class.deterministic_id(src2))
  end

  it "includes origin in deterministic ID" do
    origin = Glossarist::Rdf::GlossCitation.new(source: "ISO", id: "10241")
    src1 = described_class.new(status: "identical", type: "authoritative", origin: origin)
    src2 = described_class.new(status: "identical", type: "authoritative")
    expect(described_class.deterministic_id(src1)).not_to eq(described_class.deterministic_id(src2))
  end

  it "links to citation origin via gloss:sourceOrigin" do
    origin = Glossarist::Rdf::GlossCitation.new(source: "IEC", id: "60050-102")
    src = described_class.new(status: "gloss:srcstatus/identical", origin: origin)
    graph = parse_turtle(described_class.to_turtle(src))
    subj = graph.query([nil, RDF.type, RDF::URI("#{gloss}ConceptSource")]).first.subject
    origins = graph.query([subj, RDF::URI("#{gloss}sourceOrigin"), nil])
    expect(origins).not_to be_empty
  end
end

# ── GlossDetailedDefinition ──────────────────────────────────────────────

RSpec.describe Glossarist::Rdf::GlossDetailedDefinition do
  include_context "rdf graph helpers"

  it "emits gloss:DetailedDefinition type with rdf:value" do
    dd = described_class.new(content: "a test definition")
    graph = parse_turtle(described_class.to_turtle(dd))
    types = graph.query([nil, RDF.type, RDF::URI("#{gloss}DetailedDefinition")])
    expect(types).not_to be_empty

    subj = types.first.subject
    values = graph.query([subj, RDF::URI("#{rdf_ns}value"), nil])
    expect(values.first.object.to_s).to eq("a test definition")
  end

  it "includes sources when present" do
    origin = Glossarist::Rdf::GlossCitation.new(source: "ISO", id: "9001")
    source = Glossarist::Rdf::GlossConceptSource.new(origin: origin)
    dd = described_class.new(content: "definition", sources: [source])
    graph = parse_turtle(described_class.to_turtle(dd))
    sources = graph.query([nil, RDF.type, RDF::URI("#{gloss}ConceptSource")])
    expect(sources).not_to be_empty
  end
end

# ── GlossPronunciation ───────────────────────────────────────────────────

RSpec.describe Glossarist::Rdf::GlossPronunciation do
  include_context "rdf graph helpers"

  it "emits gloss:Pronunciation type and predicates" do
    pron = described_class.new(
      content: "toːkjoː",
      language: "jpn",
      script: "Latn",
      system: "IPA",
      country: "JP",
      concept_id: "test",
      lang_code: "jpn",
      index: "0",
    )
    graph = parse_turtle(described_class.to_turtle(pron))
    types = graph.query([nil, RDF.type, RDF::URI("#{gloss}Pronunciation")])
    expect(types).not_to be_empty

    subj = types.first.subject
    expect(graph.query([subj, RDF::URI("#{gloss}pronunciationContent"), nil]).first.object.to_s).to eq("toːkjoː")
    expect(graph.query([subj, RDF::URI("#{gloss}pronunciationLanguage"), nil]).first.object.to_s).to eq("jpn")
  end

  it "generates deterministic subject URI" do
    pron = described_class.new(content: "test", concept_id: "c1", lang_code: "eng", index: "0")
    t1 = described_class.to_turtle(pron)
    t2 = described_class.to_turtle(pron)
    expect(t1).to eq(t2)
  end
end

# ── GlossGrammarInfo ─────────────────────────────────────────────────────

RSpec.describe Glossarist::Rdf::GlossGrammarInfo do
  include_context "rdf graph helpers"

  it "emits gloss:GrammarInfo type" do
    gi = described_class.new(gender: ["gloss:gender/m"], number: ["gloss:number/singular"])
    graph = parse_turtle(described_class.to_turtle(gi))
    types = graph.query([nil, RDF.type, RDF::URI("#{gloss}GrammarInfo")])
    expect(types).not_to be_empty
  end

  it "emits gender and number as URI collections" do
    gi = described_class.new(gender: ["gloss:gender/m", "gloss:gender/f"], number: ["gloss:number/plural"])
    graph = parse_turtle(described_class.to_turtle(gi))
    subj = graph.query([nil, RDF.type, RDF::URI("#{gloss}GrammarInfo")]).first.subject
    genders = graph.query([subj, RDF::URI("#{gloss}gender"), nil])
    expect(genders.count).to eq(2)
    numbers = graph.query([subj, RDF::URI("#{gloss}number"), nil])
    expect(numbers.count).to eq(1)
  end

  it "emits part of speech as boolean predicates" do
    gi = described_class.new(part_of_speech: "noun", concept_id: "c1", lang_code: "eng", index: "0")
    graph = parse_turtle(described_class.to_turtle(gi))
    subj = graph.query([nil, RDF.type, RDF::URI("#{gloss}GrammarInfo")]).first.subject
    noun_stmts = graph.query([subj, RDF::URI("#{gloss}isNoun"), nil])
    expect(noun_stmts.count).to eq(1)
    expect(noun_stmts.first.object.value).to eq("true")
  end

  it "emits true for matching and false for non-matching part of speech" do
    gi = described_class.new(part_of_speech: "verb", concept_id: "c1", lang_code: "eng", index: "0")
    graph = parse_turtle(described_class.to_turtle(gi))
    subj = graph.query([nil, RDF.type, RDF::URI("#{gloss}GrammarInfo")]).first.subject
    verb_stmts = graph.query([subj, RDF::URI("#{gloss}isVerb"), nil])
    noun_stmts = graph.query([subj, RDF::URI("#{gloss}isNoun"), nil])
    expect(verb_stmts.first.object.value).to eq("true")
    expect(noun_stmts.first.object.value).to eq("false")
  end
end

# ── GlossConceptDate ─────────────────────────────────────────────────────

RSpec.describe Glossarist::Rdf::GlossConceptDate do
  include_context "rdf graph helpers"

  it "emits gloss:ConceptDate with value and type" do
    cd = described_class.new(date_value: "2021-05-01", date_type: "gloss:status/accepted", concept_id: "test")
    graph = parse_turtle(described_class.to_turtle(cd))
    types = graph.query([nil, RDF.type, RDF::URI("#{gloss}ConceptDate")])
    expect(types).not_to be_empty

    subj = types.first.subject
    expect(graph.query([subj, RDF::URI("#{gloss}dateValue"), nil]).first.object.to_s).to eq("2021-05-01")
    date_type = graph.query([subj, RDF::URI("#{gloss}dateType"), nil]).first.object
    expect(date_type).to be_a(RDF::URI)
  end
end

# ── GlossConceptReference ────────────────────────────────────────────────

RSpec.describe Glossarist::Rdf::GlossConceptReference do
  include_context "rdf graph helpers"

  it "emits gloss:ConceptReference with fields" do
    ref = described_class.new(
      concept_id: "103-01",
      source: "urn:iec:std:iec:60050",
      ref_type: "domain",
      parent_id: "103-01-02",
    )
    graph = parse_turtle(described_class.to_turtle(ref))
    types = graph.query([nil, RDF.type, RDF::URI("#{gloss}ConceptReference")])
    expect(types).not_to be_empty

    subj = types.first.subject
    expect(graph.query([subj, RDF::URI("#{gloss}conceptId"), nil]).first.object.to_s).to eq("103-01")
    expect(graph.query([subj, RDF::URI("#{gloss}refType"), nil]).first.object.to_s).to eq("domain")
  end
end

# ── GlossNonVerbalRep ────────────────────────────────────────────────────

RSpec.describe Glossarist::Rdf::GlossNonVerbalRep do
  include_context "rdf graph helpers"

  it "emits gloss:NonVerbalRepresentation with type and ref" do
    nvr = described_class.new(
      representation_type: "image",
      representation_ref: "assets/figure-1.svg",
      representation_text: "A diagram",
      concept_id: "test",
      lang_code: "eng",
      index: "0",
    )
    graph = parse_turtle(described_class.to_turtle(nvr))
    types = graph.query([nil, RDF.type, RDF::URI("#{gloss}NonVerbalRepresentation")])
    expect(types).not_to be_empty

    subj = types.first.subject
    expect(graph.query([subj, RDF::URI("#{gloss}representationType"), nil]).first.object.to_s).to eq("image")
    expect(graph.query([subj, RDF::URI("#{gloss}representationRef"), nil]).first.object.to_s).to eq("assets/figure-1.svg")
  end
end

# ── GlossDesignation (base + subtypes) ───────────────────────────────────

RSpec.describe Glossarist::Rdf::GlossDesignation do
  include_context "rdf graph helpers"

  it "emits gloss:Designation and skosxl:Label types" do
    d = described_class.new(designation: "mass", concept_id: "c1", lang_code: "eng", index: "0")
    graph = parse_turtle(described_class.to_turtle(d))
    types = graph.query([nil, RDF.type, nil]).map { |s| s.object.to_s }
    expect(types).to include("#{gloss}Designation")
    expect(types).to include("#{xl}Label")
  end

  it "emits skosxl:literalForm" do
    d = described_class.new(designation: "mass", concept_id: "c1", lang_code: "eng", index: "0")
    graph = parse_turtle(described_class.to_turtle(d))
    subj = graph.query([nil, RDF.type, RDF::URI("#{xl}Label")]).first.subject
    forms = graph.query([subj, RDF::URI("#{xl}literalForm"), nil])
    expect(forms.first.object.to_s).to eq("mass")
  end

  it "emits normative status as URI" do
    d = described_class.new(designation: "mass", normative_status: "gloss:norm/preferred",
                            concept_id: "c1", lang_code: "eng", index: "0")
    graph = parse_turtle(described_class.to_turtle(d))
    subj = graph.query([nil, RDF.type, RDF::URI("#{gloss}Designation")]).first.subject
    status = graph.query([subj, RDF::URI("#{gloss}normativeStatus"), nil]).first.object
    expect(status).to be_a(RDF::URI)
  end

  it "includes Relationships module" do
    d = described_class.new(designation: "test", concept_id: "c1", lang_code: "eng", index: "0")
    expect(d).to be_a(Glossarist::Rdf::Relationships)
  end

  it "emits relationship triples" do
    d = described_class.new(designation: "LED", concept_id: "c1", lang_code: "eng", index: "0")
    d.relationship_triples = [["#{gloss}abbreviatedFormFor", "concept/full"]]
    graph = parse_turtle(described_class.to_turtle(d))
    rels = graph.query([nil, RDF::URI("#{gloss}abbreviatedFormFor"), nil])
    expect(rels.count).to eq(1)
  end
end

RSpec.describe Glossarist::Rdf::GlossExpression do
  include_context "rdf graph helpers"

  it "emits gloss:Expression type" do
    e = described_class.new(designation: "color", concept_id: "c1", lang_code: "eng", index: "0",
                            usage_info: "science", field_of_application: "physics")
    graph = parse_turtle(described_class.to_turtle(e))
    types = graph.query([nil, RDF.type, nil]).map { |s| s.object.to_s }
    expect(types).to include("#{gloss}Expression")
    expect(types).to include("#{xl}Label")
  end

  it "emits expression-specific predicates" do
    e = described_class.new(designation: "color", concept_id: "c1", lang_code: "eng", index: "0",
                            usage_info: "science", field_of_application: "physics")
    graph = parse_turtle(described_class.to_turtle(e))
    subj = graph.query([nil, RDF.type, RDF::URI("#{gloss}Expression")]).first.subject
    expect(graph.query([subj, RDF::URI("#{gloss}usageInfo"), nil]).first.object.to_s).to eq("science")
    expect(graph.query([subj, RDF::URI("#{gloss}fieldOfApplication"), nil]).first.object.to_s).to eq("physics")
  end

  it "emits grammar info members" do
    gi = Glossarist::Rdf::GlossGrammarInfo.new(
      gender: ["gloss:gender/n"], number: ["gloss:number/singular"],
      concept_id: "c1", lang_code: "eng", index: "0"
    )
    e = described_class.new(designation: "resistance", concept_id: "c1", lang_code: "eng", index: "0",
                            grammar_info: [gi])
    graph = parse_turtle(described_class.to_turtle(e))
    grammar = graph.query([nil, RDF.type, RDF::URI("#{gloss}GrammarInfo")])
    expect(grammar).not_to be_empty
  end
end

RSpec.describe Glossarist::Rdf::GlossAbbreviation do
  include_context "rdf graph helpers"

  it "emits gloss:Abbreviation type with acronym flag" do
    a = described_class.new(designation: "LED", concept_id: "c1", lang_code: "eng", index: "0",
                            acronym: true)
    graph = parse_turtle(described_class.to_turtle(a))
    types = graph.query([nil, RDF.type, nil]).map { |s| s.object.to_s }
    expect(types).to include("#{gloss}Abbreviation")
    expect(types).to include("#{xl}Label")
  end

  it "emits abbreviation type booleans" do
    a = described_class.new(designation: "WWW", concept_id: "c1", lang_code: "eng", index: "0",
                            initialism: true)
    graph = parse_turtle(described_class.to_turtle(a))
    subj = graph.query([nil, RDF.type, RDF::URI("#{gloss}Abbreviation")]).first.subject
    init = graph.query([subj, RDF::URI("#{gloss}isInitialism"), nil])
    expect(init.count).to eq(1)
  end

  it "emits grammar info for abbreviation designations" do
    gi = Glossarist::Rdf::GlossGrammarInfo.new(
      part_of_speech: "noun", concept_id: "c1",
      lang_code: "eng", index: "0"
    )
    a = described_class.new(designation: "LED", concept_id: "c1", lang_code: "eng", index: "0",
                            grammar_info: [gi], acronym: true)
    graph = parse_turtle(described_class.to_turtle(a))
    grammar = graph.query([nil, RDF.type, RDF::URI("#{gloss}GrammarInfo")])
    expect(grammar).not_to be_empty
  end
end

RSpec.describe Glossarist::Rdf::GlossSymbol do
  include_context "rdf graph helpers"

  it "emits gloss:Symbol type" do
    s = described_class.new(designation: "Ω", concept_id: "c1", lang_code: "eng", index: "0",
                            international: true)
    graph = parse_turtle(described_class.to_turtle(s))
    types = graph.query([nil, RDF.type, nil]).map { |t| t.object.to_s }
    expect(types).to include("#{gloss}Symbol")
  end
end

RSpec.describe Glossarist::Rdf::GlossLetterSymbol do
  include_context "rdf graph helpers"

  it "emits gloss:LetterSymbol with text" do
    ls = described_class.new(designation: "R", text: "R", concept_id: "c1", lang_code: "eng", index: "0")
    graph = parse_turtle(described_class.to_turtle(ls))
    types = graph.query([nil, RDF.type, nil]).map { |t| t.object.to_s }
    expect(types).to include("#{gloss}LetterSymbol")
    subj = graph.query([nil, RDF.type, RDF::URI("#{gloss}LetterSymbol")]).first.subject
    expect(graph.query([subj, RDF::URI("#{gloss}text"), nil]).first.object.to_s).to eq("R")
  end
end

RSpec.describe Glossarist::Rdf::GlossGraphicalSymbol do
  include_context "rdf graph helpers"

  it "emits gloss:GraphicalSymbol with text and image" do
    gs = described_class.new(designation: "warning", text: "general warning", image: "⚠",
                             concept_id: "c1", lang_code: "eng", index: "0")
    graph = parse_turtle(described_class.to_turtle(gs))
    types = graph.query([nil, RDF.type, nil]).map { |t| t.object.to_s }
    expect(types).to include("#{gloss}GraphicalSymbol")
    subj = graph.query([nil, RDF.type, RDF::URI("#{gloss}GraphicalSymbol")]).first.subject
    expect(graph.query([subj, RDF::URI("#{gloss}text"), nil]).first.object.to_s).to eq("general warning")
    expect(graph.query([subj, RDF::URI("#{gloss}image"), nil]).first.object.to_s).to eq("⚠")
  end
end

# ── GlossLocalizedConcept ────────────────────────────────────────────────

RSpec.describe Glossarist::Rdf::GlossLocalizedConcept do
  include_context "rdf graph helpers"

  it "emits gloss:LocalizedConcept and skos:Concept types" do
    lc = described_class.new(concept_id: "c1", language_code: "eng")
    graph = parse_turtle(described_class.to_turtle(lc))
    types = graph.query([nil, RDF.type, nil]).map { |t| t.object.to_s }
    expect(types).to include("#{gloss}LocalizedConcept")
    expect(types).to include("#{skos}Concept")
  end

  it "emits dcterms:language" do
    lc = described_class.new(concept_id: "c1", language_code: "eng")
    graph = parse_turtle(described_class.to_turtle(lc))
    subj = graph.query([nil, RDF.type, RDF::URI("#{gloss}LocalizedConcept")]).first.subject
    langs = graph.query([subj, RDF::URI("#{dct}language"), nil])
    expect(langs.first.object.to_s).to eq("eng")
  end

  it "uses skosxl:prefLabel for preferred designations" do
    desig = Glossarist::Rdf::GlossExpression.new(
      designation: "mass", normative_status: "gloss:norm/preferred",
      concept_id: "c1", lang_code: "eng", index: "0"
    )
    lc = described_class.new(concept_id: "c1", language_code: "eng", designations: [desig])
    graph = parse_turtle(described_class.to_turtle(lc))
    pref = graph.query([nil, RDF::URI("#{xl}prefLabel"), nil])
    expect(pref.count).to eq(1)
  end

  it "uses skosxl:hiddenLabel for deprecated designations" do
    desig = Glossarist::Rdf::GlossExpression.new(
      designation: "old term", normative_status: "gloss:norm/deprecated",
      concept_id: "c1", lang_code: "eng", index: "0"
    )
    lc = described_class.new(concept_id: "c1", language_code: "eng", designations: [desig])
    graph = parse_turtle(described_class.to_turtle(lc))
    hidden = graph.query([nil, RDF::URI("#{xl}hiddenLabel"), nil])
    expect(hidden.count).to eq(1)
  end

  it "uses skosxl:altLabel for admitted designations" do
    desig = Glossarist::Rdf::GlossExpression.new(
      designation: "alternative", normative_status: "gloss:norm/admitted",
      concept_id: "c1", lang_code: "eng", index: "0"
    )
    lc = described_class.new(concept_id: "c1", language_code: "eng", designations: [desig])
    graph = parse_turtle(described_class.to_turtle(lc))
    alt = graph.query([nil, RDF::URI("#{xl}altLabel"), nil])
    expect(alt.count).to eq(1)
  end
end

# ── GlossConcept ─────────────────────────────────────────────────────────

RSpec.describe Glossarist::Rdf::GlossConcept do
  include_context "rdf graph helpers"

  it "emits gloss:Concept and skos:Concept types" do
    gc = described_class.new(identifier: "test-1")
    graph = parse_turtle(described_class.to_turtle(gc))
    types = graph.query([nil, RDF.type, nil]).map { |t| t.object.to_s }
    expect(types).to include("#{gloss}Concept")
    expect(types).to include("#{skos}Concept")
  end

  it "emits identifier and status" do
    gc = described_class.new(identifier: "102-03-01", status: "gloss:status/valid")
    graph = parse_turtle(described_class.to_turtle(gc))
    subj = graph.query([nil, RDF.type, RDF::URI("#{gloss}Concept")]).first.subject
    expect(graph.query([subj, RDF::URI("#{gloss}identifier"), nil]).first.object.to_s).to eq("102-03-01")
    status = graph.query([subj, RDF::URI("#{gloss}hasStatus"), nil]).first.object
    expect(status).to be_a(RDF::URI)
  end

  it "includes Relationships module" do
    gc = described_class.new(identifier: "test")
    expect(gc).to be_a(Glossarist::Rdf::Relationships)
  end

  it "emits relationship triples" do
    gc = described_class.new(identifier: "c1")
    gc.relationship_triples = [
      ["#{skos}broader", "concept/parent"],
      ["#{skos}exactMatch", "concept/equivalent"],
    ]
    graph = parse_turtle(described_class.to_turtle(gc))
    broader = graph.query([nil, RDF::URI("#{skos}broader"), nil])
    expect(broader.count).to eq(1)
  end
end
