# frozen_string_literal: true

module Glossarist
  class ConceptManager
    # Path to concepts directory.
    # @return [String]
    attr_accessor :path

    def initialize(path: nil)
      @path = path
    end

    # Reads all concepts from files.
    def load_from_files(collection: nil)
      collection ||= ManagedConceptCollection.new

      Dir.glob(concepts_glob) do |filename|
        collection.store(load_concept_from_file(filename))
      end
    end

    # Writes all concepts to files.
    def save_to_files(managed_concepts)
      managed_concepts.each_value &method(:save_concept_to_file)
    end

    private

    def load_concept_from_file(filename)
      ManagedConcept.new(Psych.safe_load(File.read(filename)))
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
