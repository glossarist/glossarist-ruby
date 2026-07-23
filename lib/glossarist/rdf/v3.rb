# frozen_string_literal: true

module Glossarist
  module Rdf
    module V3
      autoload :Configuration, "glossarist/rdf/v3/configuration"

      VIEW_CLASS_NAMES = %i[
        GlossLocality
        GlossPronunciation
        GlossGrammarInfo
        GlossConceptDate
        GlossReference
        GlossConceptSource
        GlossDetailedDefinition
        GlossNonVerbalRep
        GlossDesignation
        GlossExpression
        GlossAbbreviation
        GlossSymbol
        GlossLetterSymbol
        GlossGraphicalSymbol
        GlossPrefix
        GlossSuffix
        GlossLocalizedConcept
        GlossConcept
        GlossDocument
        GlossFigure
        GlossFigureImage
        GlossTable
        GlossFormula
        GlossPartitiveRelation
        GlossPartitiveMember
        GlossTypeSharedPlurality
      ].freeze

      VIEW_CLASS_NAMES.each do |name|
        klass = ::Glossarist::Rdf.const_get(name)
        registry_id = name.to_s
          .gsub(/([A-Z])/) { |c| "_#{c.downcase}" }
          .sub(/^_/, "").to_sym
        Configuration.register_model(klass, id: registry_id)
        const_set(name, klass)
      end
    end
  end
end
