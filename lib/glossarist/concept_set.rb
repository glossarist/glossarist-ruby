# frozen_string_literal: true

module Glossarist
  class ConceptSet
    # a `Glossarist::ManagedConceptCollection` object
    attr_accessor :concepts

    # a `BibliographyCollection` object
    attr_accessor :bibliographies

    # an `Collections::Asset` object
    attr_accessor :assets

    def initialize(concepts, assets)
      @concepts = concepts
      @assets = Glossarist::Collections::AssetCollection.new(assets)
      @bibliographies = Glossarist::Collections::BibliographyCollection.new(concepts, nil, nil)
    end
  end
end
