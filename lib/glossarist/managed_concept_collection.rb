# frozen_string_literal: true

module Glossarist
  class ManagedConceptCollection
    include Enumerable

    def initialize
      @managed_concepts = {}
      @managed_concepts_ids = {}
      @concept_manager = ConceptManager.new
    end

    # @return [Array<ManagedConcept>]
    def managed_concepts
      @managed_concepts.values
    end

    def managed_concepts=(managed_concepts = [])
      managed_concepts.each do |managed_concept|
        store(ManagedConcept.new(managed_concept))
      end

      @managed_concepts.values
    end

    def to_h
      {
        "managed_concepts" => managed_concepts.map(&:to_h),
      }.compact
    end

    def each(&block)
      @managed_concepts.each_value(&block)
    end

    # Returns concept with given ID, if it is present in collection, or +nil+
    # otherwise.
    #
    # @param id [String]
    #    ManagedConcept ID
    # @return [ManagedConcept, nil]
    def fetch(id)
      @managed_concepts[id] || @managed_concepts[@managed_concepts_ids[id]]
    end

    alias :[] :fetch

    # If ManagedConcept with given ID is present in this collection, then
    # returns it. Otherwise, instantiates a new ManagedConcept, adds it to
    # the collection, and returns it.
    #
    # @param id [String]
    #    ManagedConcept ID
    # @return [ManagedConcept]
    def fetch_or_initialize(id)
      fetch(id) or store(ManagedConcept.new(data: { id: id }))
    end

    # Adds concept to the collection. If collection contains a concept with
    # the same ID already, that concept is replaced.
    #
    # @param managed_concept [ManagedConcept]
    #   ManagedConcept about to be added
    def store(managed_concept)
      @managed_concepts[managed_concept.uuid] = managed_concept
      @managed_concepts_ids[managed_concept.id] = managed_concept.uuid if managed_concept.id

      managed_concept
    end

    alias :<< :store

    def load_from_files(path)
      @concept_manager.path = path
      @concept_manager.load_from_files(collection: self)
    end

    def save_to_files(path)
      @concept_manager.path = path
      @concept_manager.save_to_files(@managed_concepts)
    end
  end
end
