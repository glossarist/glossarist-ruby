# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module Glossarist
  class Collection
    include Enumerable

    def initialize()
      @index = {}
    end

    def each(&block)
      @index.each_value(&block)
    end

    # Returns concept with given ID, if it is present in collection, or +nil+
    # otherwise.
    #
    # @param id [String]
    #    Concept ID
    # @return [Concept, nil]
    def fetch(id)
      @index[id]
    end

    alias :[] :fetch

    # Adds concept to the collection.  If collection contains a concept with
    # the same ID already, that concept is replaced.
    #
    # @param concept [Concept]
    #   concept about to be added
    def store(concept)
      @index[concept.id] = concept
    end

    alias :<< :store
  end
end
