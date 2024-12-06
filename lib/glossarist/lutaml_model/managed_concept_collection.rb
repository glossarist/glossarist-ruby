module Glossarist
  module LutamlModel
    class ManagedConceptCollection < Lutaml::Model::Serializable
      include Enumerable

      attribute :managed_concepts_ids, :hash, default: -> { {} }
      attribute :managed_concepts, ManagedConcept, collection: true
      attribute :concept_manager, ConceptManager, default: -> { ConceptManager.new }

      yaml do
        map :managed_concepts_ids, to: :managed_concepts_ids
        map :managed_concepts, to: :managed_concepts
        map :concept_manager, to: :concept_manager
      end

      def initialize(attrs = {})
        super

        @managed_concepts ||= {}
      end

      def managed_concepts
        @managed_concepts.values
      end

      def managed_concepts=(managed_concepts = [])
        managed_concepts.each do |managed_concept|
          managed_concept = Config.class_for(:managed_concept).new(managed_concept) if managed_concept.is_a?(Hash)

          store(managed_concept)
        end
      end

      def to_h
        {
          "managed_concepts" => managed_concepts.map(&:to_yaml_hash),
        }.compact
      end

      def each(&block)
        @managed_concepts.each_value(&block)
      end

      def fetch(id)
        @managed_concepts[id] || @managed_concepts[@managed_concepts_ids[id]]
      end
      alias :[] :fetch

      def fetch_or_initialize(id)
        fetch(id) or store(Config.class_for(:managed_concept).new(data: { id: id }))
      end

      def store(managed_concept)
        @managed_concepts[managed_concept.uuid] = managed_concept
        @managed_concepts_ids[managed_concept.id] = managed_concept.uuid if managed_concept.id

        managed_concept
      end
      alias :<< :store

      def load_from_files(path)
        @concept_manager.path = path
        @concept_manager.load_from_files(collection: self)
      end

      def save_to_files(path)
        @concept_manager.path = path
        @concept_manager.save_to_files(@managed_concepts)
      end
    end
  end
end
