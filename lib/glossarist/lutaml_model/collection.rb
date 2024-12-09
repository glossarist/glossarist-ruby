module Glossarist
  module LutamlModel
    class Collection < Lutaml::Model::Serializable
      include Enumerable

      attribute :path, :string
      attribute :index, :hash
      attribute :fetch, :string
      attribute :store, :string

      alias :[] :fetch
      alias :<< :store

      yaml do
        map :path, to: :path
        map :index, to: :index
        map :fetch, to: :fetch
        map :store, to: :store
      end

      def each(&block)
        @index.each_value(&block)
      end

      def fetch(id)
        @index[id]
      end

      def fetch_or_initialize(id)
        fetch(id) or store(Concept.new(id: id))
      end

      def store(concept)
        @index[concept.id] = concept
      end

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
        Concept.from_h(Psych.safe_load(File.read(filename)))
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
end
