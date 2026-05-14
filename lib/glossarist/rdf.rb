# frozen_string_literal: true

# Load lutaml-model RDF extensions before any RDF view classes
require_relative "rdf/ext"

module Glossarist
  module Rdf
    autoload :Namespaces, "#{__dir__}/rdf/namespaces"
    autoload :LocalizedLiteral, "#{__dir__}/rdf/localized_literal"
    autoload :Relationships, "#{__dir__}/rdf/relationships"
    autoload :GlossLocality, "#{__dir__}/rdf/gloss_locality"
    autoload :GlossCitation, "#{__dir__}/rdf/gloss_citation"
    autoload :GlossConceptSource, "#{__dir__}/rdf/gloss_concept_source"
    autoload :GlossDetailedDefinition, "#{__dir__}/rdf/gloss_detailed_definition"
    autoload :GlossPronunciation, "#{__dir__}/rdf/gloss_pronunciation"
    autoload :GlossGrammarInfo, "#{__dir__}/rdf/gloss_grammar_info"
    autoload :GlossNonVerbalRep, "#{__dir__}/rdf/gloss_non_verbal_rep"
    autoload :GlossConceptReference, "#{__dir__}/rdf/gloss_concept_reference"
    autoload :GlossConceptDate, "#{__dir__}/rdf/gloss_concept_date"
    autoload :GlossDesignation, "#{__dir__}/rdf/gloss_designation"
    autoload :GlossExpression, "#{__dir__}/rdf/gloss_designation"
    autoload :GlossAbbreviation, "#{__dir__}/rdf/gloss_designation"
    autoload :GlossSymbol, "#{__dir__}/rdf/gloss_designation"
    autoload :GlossLetterSymbol, "#{__dir__}/rdf/gloss_designation"
    autoload :GlossGraphicalSymbol, "#{__dir__}/rdf/gloss_designation"
    autoload :GlossLocalizedConcept, "#{__dir__}/rdf/gloss_localized_concept"
    autoload :GlossConcept, "#{__dir__}/rdf/gloss_concept"
    autoload :GlossDocument, "#{__dir__}/rdf/gloss_concept"
  end
end
