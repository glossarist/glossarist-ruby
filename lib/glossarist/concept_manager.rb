module Glossarist
  class ConceptManager < Lutaml::Model::Serializable
    attribute :path, :string
    attribute :localized_concepts_path, :string

    key_value do
      map :path, to: :path
      map %i[localized_concepts_path localizedConceptsPath],
          to: :localized_concepts_path
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

    def load_concept_from_file(filename) # rubocop:disable Metrics/CyclomaticComplexity
      raw = File.read(filename, encoding: "utf-8")
      doc = ConceptDocument.from_yamls(raw)
      concept = doc.concept
      unless concept
        raise Glossarist::ParseError.new(filename: filename)
      end

      concept_uuid = concept.identifier || concept.data&.id || File.basename(
        filename, ".*"
      )
      concept.instance_variable_set(:@uuid, concept_uuid)

      concept.data.localized_concepts.each_value do |id|
        localized_concept = load_localized_concept(id, doc.localizations)
        concept.add_l10n(localized_concept)
      end

      [concept]
    rescue Psych::SyntaxError => e
      raise Glossarist::ParseError.new(filename: filename, line: e.line)
    end

    def load_localized_concept(id, inline_localizations = nil)
      if inline_localizations
        l10n = inline_localizations.find { |l| l.id == id }
        if l10n
          l10n.instance_variable_set(:@uuid, id)
          return l10n
        end
      end

      l10n = LocalizedConcept.from_yaml(
        File.read(localized_concept_path(id), encoding: "utf-8"),
      )
      l10n.instance_variable_set(:@uuid, id)
      l10n
    rescue Psych::SyntaxError => e
      raise Glossarist::ParseError.new(filename: filename, line: e.line)
    end

    def save_concept_to_file(concept)
      @localized_concepts_path ||= "localized_concept"
      concept_dir = File.join(path, "concept")

      localized_concept_dir = File.join(path, @localized_concepts_path)

      FileUtils.mkdir_p(concept_dir)
      FileUtils.mkdir_p(localized_concept_dir)

      filename = File.join(concept_dir, "#{concept.uuid}.yaml")
      File.write(filename, concept.to_yaml, encoding: "utf-8")

      concept.localized_concepts.each do |lang, uuid|
        filename = File.join(localized_concept_dir, "#{uuid}.yaml")
        File.write(filename, concept.localization(lang).to_yaml,
                   encoding: "utf-8")
      end
    end

    def save_grouped_concepts_to_file(concept)
      @localized_concepts_path ||= "localized_concept"
      concept_dir = File.join(path)

      FileUtils.mkdir_p(concept_dir)

      content = []

      filename = File.join(concept_dir, "#{concept.uuid}.yaml")
      content << concept.to_yaml

      concept.localized_concepts.each_key do |lang|
        content << concept.localization(lang).to_yaml
      end

      File.write(filename, content.join("\n"), encoding: "utf-8")
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
