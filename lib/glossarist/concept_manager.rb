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
        concept = if v1_collection?
                    Glossarist::V1Reader.load_concept_from_file(filename)
                  else
                    load_concept_from_file(filename)
                  end

        collection.store(concept)
      end
    end

    # Writes all concepts to files.
    def save_to_files(managed_concepts)
      managed_concepts.each_value &method(:save_concept_to_file)
    end

    def load_concept_from_file(filename)
      concept_hash = Psych.safe_load(File.read(filename), permitted_classes: [Date, Time])
      concept_hash["uuid"] = concept_hash["id"] || File.basename(filename, ".*")

      concept = Config.class_for(:managed_concept).new(concept_hash)
      concept.localized_concepts.each do |_lang, id|
        localized_concept = load_localized_concept(id)
        concept.add_l10n(localized_concept)
      end

      concept
    rescue Psych::SyntaxError => e
      raise Glossarist::ParseError.new(filename: filename, line: e.line)
    end

    def load_localized_concept(id)
      concept_hash = Psych.safe_load(
        File.read(localized_concept_path(id)),
        permitted_classes: [Date, Time],
      )
      concept_hash["uuid"] = id

      Config.class_for(:localized_concept).new(concept_hash)
    rescue Psych::SyntaxError => e
      raise Glossarist::ParseError.new(filename: filename, line: e.line)
    end

    def save_concept_to_file(concept)
      concept_dir = File.join(path, "concept")
      localized_concept_dir = File.join(path, "localized_concept")

      Dir.mkdir(concept_dir) unless Dir.exist?(concept_dir)
      Dir.mkdir(localized_concept_dir) unless Dir.exist?(localized_concept_dir)

      filename = File.join(concept_dir, "#{concept.uuid}.yaml")
      File.write(filename, Psych.dump(concept.to_h))

      concept.localized_concepts.each do |lang, uuid|
        filename = File.join(localized_concept_dir, "#{uuid}.yaml")
        File.write(filename, Psych.dump(concept.localization(lang).to_h))
      end
    end

    private

    def concepts_glob
      if v1_collection?
        File.join(path, "concept-*.{yaml,yml}")
      else
        File.join(path, "concept", "*.{yaml,yml}")
      end
    end

    def localized_concept_path(id)
      Dir.glob(File.join(path, "localized_concept", "#{id}.{yaml,yml}"))&.first
    end

    def v1_collection?
      @v1_collection ||= !Dir.glob(File.join(path, "concept-*.{yaml,yml}")).empty?
    end
  end
end
