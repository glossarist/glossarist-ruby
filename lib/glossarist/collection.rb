module Glossarist
  class Collection < Lutaml::Model::Serializable
    include Enumerable

    attribute :path, :string
    attribute :index, :hash, default: -> { {} }

    yaml do
      map :path, to: :path
      map :index, to: :index, render_default: true
    end

    def each(&block)
      @index.each_value(&block)
    end

    def fetch(id)
      @index[id]
    end
    alias :[] :fetch

    def fetch_or_initialize(id)
      fetch(id) or store(Concept.of_yaml({ id: id }))
    end

    def store(concept)
      @index[concept.id] = concept
    end
    alias :<< :store

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
