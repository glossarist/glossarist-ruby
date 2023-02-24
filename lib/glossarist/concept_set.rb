# frozen_string_literal: true

module Glossarist
  class ConceptSet
    # a `Glossarist::ManagedConceptCollection` object
    attr_accessor :concepts

    # a `BibliographyCollection` object
    attr_accessor :bibliographies

    # an `Collections::Asset` object
    attr_accessor :assets

    # @parameters
    #   concepts => a `Glossarist::ManagedConceptCollection` object or
    #               a string containing the path of the folder with concepts
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

    def to_latex(entries_file)
      latex_content = File.readlines(entries_file).map do |concept_name|
        concept = concept_map[concept_name.strip]

        latex_template(concept)
      end.join("\n")
    end

    private

    def read_concepts(concepts)
      return concepts if concepts.is_a?(Glossarist::ManagedConceptCollection)

      collection = Glossarist::ManagedConceptCollection.new
      collection.load_from_files(concepts)
      collection
    end

    def latex_template(concept)
      <<~TEMPLATE
        \\newglossaryentry{#{concept.default_designation.gsub('_', '-')}}
        {
        name={#{concept.default_designation.gsub('_', '\_')}}
        description={#{normalize_definition(concept.default_definition)}}
        }
      TEMPLATE
    end

    def normalize_definition(definition)
      definition.gsub(/{{([^}]*)}}/) do |match|
        "\\textbf{\\gls{#{Regexp.last_match[1].gsub('_', '-')}}}"
      end
    end

    def concept_map
      @concept_map ||= concepts.managed_concepts.map do |concept|
        [concept.default_designation, concept]
      end.to_h
    end
  end
end
