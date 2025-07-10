module Glossarist
  class ConceptManager < Lutaml::Model::Serializable
    attribute :path, :string
    attribute :localized_concepts_path, :string

    yaml do
      map :path, to: :path
      map %i[localized_concepts_path localizedConceptsPath], to: :localized_concepts_path
    end

    def load_from_files(collection: nil)
      collection ||= ManagedConceptCollection.new

      Dir.glob(concepts_glob) do |filename|
        concept = load_concept_from_file(filename)

        collection.store(concept)
      end
    end

    def save_to_files(managed_concepts)
      managed_concepts.each do |concept|
        save_concept_to_file(concept)
      end
    end

    def load_concept_from_file(filename)
      concept_hash = Psych.safe_load(File.read(filename),
                                     permitted_classes: [Date, Time])
      concept_hash["uuid"] = concept_hash["id"] || File.basename(filename, ".*")

      concept = Config.class_for(:managed_concept).of_yaml(concept_hash)

      concept.data.localized_concepts.each_value do |id|
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

      Config.class_for(:localized_concept).of_yaml(concept_hash)
    rescue Psych::SyntaxError => e
      raise Glossarist::ParseError.new(filename: filename, line: e.line)
    end

    def save_concept_to_file(concept)
      @localized_concepts_path ||= "localized_concept"
      concept_dir = File.join(path, "concept")

      localized_concept_dir = File.join(path, @localized_concepts_path)

      Dir.mkdir(concept_dir) unless Dir.exist?(concept_dir)
      Dir.mkdir(localized_concept_dir) unless Dir.exist?(localized_concept_dir)

      filename = File.join(concept_dir, "#{concept.uuid}.yaml")
      File.write(filename, concept.to_yaml)

      concept.localized_concepts.each do |lang, uuid|
        filename = File.join(localized_concept_dir, "#{uuid}.yaml")
        File.write(filename, concept.localization(lang).to_yaml)
      end
    end

    def concepts_glob
      if v1_collection?
        File.join(path, "concept-*.{yaml,yml}")
      else
        File.join(path, "concept", "*.{yaml,yml}")
      end
    end

    def localized_concept_path(id)
      localized_concept_possible_dir = {
        "localized_concept" => File.join(
          path,
          "localized_concept",
          "#{id}.{yaml,yml}",
        ),

        "localized-concept" => File.join(
          path,
          "localized-concept",
          "#{id}.{yaml,yml}",
        ),
      }

      localized_concept_possible_dir.each do |dir_name, file_path|
        actual_path = Dir.glob(file_path)&.first

        if actual_path
          @localized_concepts_path = dir_name
          return actual_path
        end
      end
    end

    def v1_collection?
      @v1_collection ||= !Dir.glob(File.join(path,
                                             "concept-*.{yaml,yml}")).empty?
    end
  end
end
