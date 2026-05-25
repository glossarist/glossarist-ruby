# frozen_string_literal: true

# Load shared infrastructure first
require_relative "ext"
require_relative "namespaces"
require_relative "relationships"
require_relative "localized_literal"

# V3 Configuration must be loaded before view classes are registered
require_relative "v3/configuration"

# Load all view class files (must precede V3 constant assignments)
require_relative "gloss_locality"
require_relative "gloss_reference"
require_relative "gloss_concept_source"
require_relative "gloss_detailed_definition"
require_relative "gloss_pronunciation"
require_relative "gloss_grammar_info"
require_relative "gloss_non_verbal_rep"
require_relative "gloss_concept_date"
require_relative "gloss_designation"
require_relative "gloss_localized_concept"
require_relative "gloss_concept"

module Glossarist
  module Rdf
    # V3 is the current (and only) RDF schema version.
    #
    # All RDF view classes produce v3 gloss ontology output:
    # namespace URI: https://www.glossarist.org/ontologies/v3/
    #
    # Each version has its own Configuration module with a unique CONTEXT_ID
    # so that V3 and (future) V4 classes are isolated in separate
    # Lutaml::Model::GlobalContext registries.
    #
    # When v4 is added:
    #   - Create Rdf::V4::Configuration with CONTEXT_ID = :glossarist_rdf_v4
    #   - Create V4 view classes (standalone or inheriting from V3)
    #   - Register V4 classes in Rdf::V4::Configuration
    #   - Update ConceptToGlossTransform to support v4
    #   - V3 and V4 coexist — consumers choose which to use
    module V3
      # Namespace
      GlossaristNamespace = Namespaces::GlossaristNamespace

      # Single source of truth: add new view classes here once.
      # Each entry is registered in the V3 type registry and
      # re-exported as a V3:: constant.
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
      ].freeze

      VIEW_CLASS_NAMES.each do |name|
        klass = ::Glossarist::Rdf.const_get(name)
        registry_id = name.to_s.gsub(/([A-Z])/) { |c| "_#{c.downcase}" }.sub(/^_/, "").to_sym
        Configuration.register_model(klass, id: registry_id)
        const_set(name, klass)
      end
    end
  end
end
