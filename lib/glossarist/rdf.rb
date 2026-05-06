# frozen_string_literal: true

module Glossarist
  module Rdf
    autoload :Namespaces, "#{__dir__}/rdf/namespaces"
    autoload :LocalizedLiteral, "#{__dir__}/rdf/localized_literal"
    autoload :SkosConcept, "#{__dir__}/rdf/skos_concept"
    autoload :SkosVocabulary, "#{__dir__}/rdf/skos_vocabulary"
  end
end
