# frozen_string_literal: true

require "set"

module Glossarist
  class ConceptSet
    # An Enumerable of ManagedConcept (Array, GlossaryStore, or
    # ManagedConceptCollection). Set by `read_concepts` based on what
    # the caller passed.
    attr_accessor :concepts

    # a `BibliographyCollection` object
    attr_accessor :bibliographies

    # an `Collections::Asset` object
    attr_accessor :assets

    # @parameters
    #   concepts => an Enumerable of ManagedConcept, a GlossaryStore, a
    #               ManagedConceptCollection, or a string containing the
    #               path of the dataset directory
    #   assets => a collection of Glossarist::Asset
    def initialize(concepts, assets, options = {})
      @concepts = read_concepts(concepts)
      @assets = Glossarist::Collections::AssetCollection.new(assets)
      @bibliographies = Glossarist::Collections::BibliographyCollection.new(
        @concepts,
        options.dig(:bibliography, :global_cache),
        options.dig(:bibliography, :local_cache),
      )
    end

    def to_latex(filename = nil)
      return to_latex_from_file(filename) if filename

      concepts.to_a.map do |concept|
        latex_template(concept)
      end.join("\n")
    end

    def to_latex_from_file(entries_file)
      File.readlines(entries_file).filter_map do |concept_name|
        concept = concept_map[concept_name.strip.downcase]

        if concept.nil?
          puts "  [Not Found]: #{concept_name.strip}"
        else
          latex_template(concept)
        end
      end.join("\n")
    end

    # Loads concepts via GlossaryStore when given a path string. Accepts
    # an existing Enumerable (Array, GlossaryStore, ManagedConceptCollection)
    # as-is — callers that already have an in-memory collection can pass
    # it directly without paying for a re-load.
    def read_concepts(concepts)
      return concepts if concepts.is_a?(Enumerable)

      store = GlossaryStore.new
      store.load(concepts)
      store.concepts
    end

    def latex_template(concept)
      <<~TEMPLATE
        \\newglossaryentry{#{concept.default_designation.tr('_', '-')}}
        {
        name={#{concept.default_designation.gsub('_', '\_')}}
        description={#{normalize_definition(concept.default_definition)}}
        }
      TEMPLATE
    end

    def normalize_definition(definition)
      definition.gsub(/{{([^}]*)}}/) do |_match|
        inner = Regexp.last_match[1]
        # Mention syntax: {{identifier}} or {{identifier, render term}}
        # Use the identifier (first part before comma) as the gloss label.
        label = inner.split(",", 2).first.strip.tr("_", "-")
        "\\textbf{\\gls{#{label}}}"
      end
    end

    def concept_map
      @concept_map ||= concepts.to_a.to_h do |concept|
        [concept.default_designation.downcase, concept]
      end
    end
  end
end
