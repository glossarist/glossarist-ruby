module Glossarist
  # @todo Add support for lazy concept loading.
  # @todo Consider extracting persistence backend to a separate class.
  class Collection
    include Enumerable

    # Path to concepts directory.
    # @return [String]
    attr_accessor :path

    # @param path [String]
    #   concepts directory path, either absolute or relative to CWD
    def initialize(path: nil)
      @path = path
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

    # If concept with given ID is present in this collection, returns that
    # concept.  Otherwise, instantiates a new concept, adds it to
    # the collection, and returns it.
    #
    # @param id [String]
    #    Concept ID
    # @return [Concept]
    def fetch_or_initialize(id)
      fetch(id) or store(Concept.of_yaml({ id: id }))
    end

    # Adds concept to the collection.  If collection contains a concept with
    # the same ID already, that concept is replaced.
    #
    # @param concept [Concept]
    #   concept about to be added
    def store(concept)
      @index[concept.id] = concept
    end
    alias :<< :store

    # Reads all concepts from files.
    def load_concepts
      Dir.glob(concepts_glob) do |filename|
        store(load_concept_from_file(filename))
      end
    end

    # Writes all concepts to files.
    def save_concepts
      @index.each_value &method(:save_concept_to_file)
    end

    def load_concept_from_file(filename)
      Concept.from_yaml(File.read(filename))
    rescue Psych::SyntaxError => e
      raise Glossarist::ParseError.new(filename: filename, line: e.line)
    end

    def save_concept_to_file(concept)
      filename = File.join(path, "concept-#{concept.id}.yaml")
      File.write(filename, Psych.dump(concept.to_h))
    end

    def concepts_glob
      File.join(path, "concept-*.{yaml,yml}")
    end
  end
end
