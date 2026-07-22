# frozen_string_literal: true

require "lutaml/rdf"
require "lutaml/turtle"
require "lutaml/jsonld"

module Glossarist
  module Rdf
    # lutaml_ext.rb defines EmitsExtraTriples (mixed into RDF model classes
    # that want to emit extra triples) and LutamlTurtleTransformExt (prepended
    # into Lutaml::Turtle::Transform so the framework asks each instance for
    # its extra triples). The prepend must run before the first transform
    # call; autoload here fires the first time EmitsExtraTriples is
    # referenced (i.e., when GlossLocalizedConcept includes it during its
    # own autoload), which is before any transform runs.
    autoload :EmitsExtraTriples,        "#{__dir__}/rdf/lutaml_ext"
    autoload :LutamlTurtleTransformExt, "#{__dir__}/rdf/lutaml_ext"

    autoload :Namespaces,             "#{__dir__}/rdf/namespaces"
    autoload :LocalizedLiteral,       "#{__dir__}/rdf/localized_literal"
    autoload :RelationshipPredicates, "#{__dir__}/rdf/relationship_predicates"
    autoload :GlossLocality,          "#{__dir__}/rdf/gloss_locality"
    autoload :GlossCitation,          "#{__dir__}/rdf/gloss_citation"
    autoload :GlossConceptSource,     "#{__dir__}/rdf/gloss_concept_source"
    autoload :GlossDetailedDefinition,
             "#{__dir__}/rdf/gloss_detailed_definition"
    autoload :GlossPronunciation,     "#{__dir__}/rdf/gloss_pronunciation"
    autoload :GlossGrammarInfo,       "#{__dir__}/rdf/gloss_grammar_info"
    autoload :GlossNonVerbalRep,      "#{__dir__}/rdf/gloss_non_verbal_rep"
    autoload :GlossConceptReference,  "#{__dir__}/rdf/gloss_concept_reference"
    autoload :GlossConceptDate,       "#{__dir__}/rdf/gloss_concept_date"
    autoload :GlossDesignation,       "#{__dir__}/rdf/gloss_designation"
    autoload :GlossExpression,        "#{__dir__}/rdf/gloss_designation"
    autoload :GlossAbbreviation,      "#{__dir__}/rdf/gloss_designation"
    autoload :GlossSymbol,            "#{__dir__}/rdf/gloss_designation"
    autoload :GlossLetterSymbol,      "#{__dir__}/rdf/gloss_designation"
    autoload :GlossGraphicalSymbol,   "#{__dir__}/rdf/gloss_designation"
    autoload :GlossLocalizedConcept,  "#{__dir__}/rdf/gloss_localized_concept"
    autoload :GlossConcept,           "#{__dir__}/rdf/gloss_concept"
    autoload :GlossDocument,          "#{__dir__}/rdf/gloss_concept"
    autoload :GlossFigure,            "#{__dir__}/rdf/gloss_figure"
    autoload :GlossFigureImage,       "#{__dir__}/rdf/gloss_figure_image"
    autoload :GlossTable,             "#{__dir__}/rdf/gloss_table"
    autoload :GlossFormula,           "#{__dir__}/rdf/gloss_formula"
    autoload :GlossHyperedge,         "#{__dir__}/rdf/gloss_hyperedge"
    autoload :V3,                     "#{__dir__}/rdf/v3"
  end
end
