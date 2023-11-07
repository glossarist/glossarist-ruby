# frozen_string_literal: true

module Glossarist
  class ConceptManager
    # Path to concepts directory.
    # @return [String]
    attr_accessor :path

    # @param path [String]
    #   concepts directory path, either absolute or relative to CWD
    def initialize(path: nil)
      @path = path
    end

    # Reads all concepts from files.
    def load_from_files(collection: nil)
      collection ||= ManagedConceptCollection.new

      Dir.glob(concepts_glob) do |filename|
        concept = load_concept_from_file(filename)
        concept.localized_concepts.each do |_lang, id|
          localized_concept = load_localized_concept(id)
          concept.add_l10n(localized_concept)
        end

        collection.store(concept)
      end
    end

    # Writes all concepts to files.
    def save_to_files(managed_concepts)
      managed_concepts.each_value &method(:save_concept_to_file)
    end

    def load_concept_from_file(filename)
      ManagedConcept.new(Psych.safe_load(File.read(filename), permitted_classes: [Date]))
    rescue Psych::SyntaxError => e
      raise Glossarist::ParseError.new(filename: filename, line: e.line)
    end

    def load_localized_concept(id)
      Config.class_for(:localized_concept).new(
        Psych.safe_load(
          File.read(localized_concept_path(id)),
          permitted_classes: [Date],
        ),
      )
    rescue Psych::SyntaxError => e
      raise Glossarist::ParseError.new(filename: filename, line: e.line)
    end

    def save_concept_to_file(concept)
      filename = File.join(path, "concept-#{concept.id}.yaml")
      File.write(filename, Psych.dump(concept.to_h))
    end

    private

    def concepts_glob
      File.join(path, "concept", "*.{yaml,yml}")
    end

    def localized_concept_path(id)
      Dir.glob(File.join(path, "localized_concept", "#{id}.{yaml,yml}"))&.first
    end
  end
end
