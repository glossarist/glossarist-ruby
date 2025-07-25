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
        concepts = load_concept_from_file(filename)

        concepts.each do |concept|
          collection.store(concept)
        end
      end
    end

    def save_to_files(managed_concepts)
      managed_concepts.each do |concept|
        save_concept_to_file(concept)
      end
    end

    def save_grouped_concepts_to_files(managed_concepts)
      managed_concepts.each do |concept|
        save_grouped_concepts_to_file(concept)
      end
    end

    def group_concept_hashes(mixed_hashes)
      concept_hashes = mixed_hashes.select do |concept_hash|
        !concept_hash["data"]["localized_concepts"].nil? ||
          !concept_hash["data"]["localizedConcepts"].nil?
      end

      localized_concept_hashes = mixed_hashes.select do |concept_hash|
        concept_hash["data"]["localized_concepts"].nil? &&
          concept_hash["data"]["localizedConcepts"].nil?
      end

      [concept_hashes, localized_concept_hashes]
    end

    def load_concept_from_file(filename)
      mixed_hashes = YAML.load_stream(File.read(filename))
      concepts = []

      concept_hashes, localized_concept_hashes =
        group_concept_hashes(mixed_hashes)

      concept_hashes.each do |concept_hash|
        concept_hash["uuid"] = concept_hash["id"] ||
          File.basename(filename, ".*")
        concept = Config.class_for(:managed_concept).of_yaml(concept_hash)

        concept.data.localized_concepts.each_value do |id|
          localized_concept =
            load_localized_concept(id, localized_concept_hashes)
          concept.add_l10n(localized_concept)
        end

        concepts << concept
      end

      concepts
    rescue Psych::SyntaxError => e
      raise Glossarist::ParseError.new(filename: filename, line: e.line)
    end

    def load_localized_concept(id, localized_concept_hashes = [])
      {}

      concept_hash = if localized_concept_hashes.empty?
                       Psych.safe_load(
                         File.read(localized_concept_path(id)),
                         permitted_classes: [Date, Time],
                       )
                     else
                       localized_concept_hashes.find do |hash|
                         hash["id"] == id
                       end
                     end

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

    def save_grouped_concepts_to_file(concept)
      @localized_concepts_path ||= "localized_concept"
      concept_dir = File.join(path)

      Dir.mkdir(concept_dir) unless Dir.exist?(concept_dir)

      content = []

      filename = File.join(concept_dir, "#{concept.uuid}.yaml")
      content << concept.to_yaml

      concept.localized_concepts.each_key do |lang|
        content << concept.localization(lang).to_yaml
      end

      File.write(filename, content.join("\n"))
    end

    def concepts_glob
      return path if File.file?(path)

      if v1_collection?
        File.join(path, "concept-*.{yaml,yml}")
      else
        # normal v2 collection
        concepts_glob = File.join(path, "concept", "*.{yaml,yml}")
        if Dir.glob(concepts_glob).empty?
          # multiple content YAML files
          concepts_glob = File.join(path, "*.{yaml,yml}")
        end
        concepts_glob
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
