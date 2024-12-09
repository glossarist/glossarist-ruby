module Glossarist
  module LutamlModel
    class ManagedConceptCollection < Lutaml::Model::Serializable
      attribute :managed_concept, :hash
      attribute :managed_concepts_ids, :hash
      attribute :concept_manager, ConceptManager
      attribute :store, :string
      attribute :fetch, :string

      alias :<< :store
      alias :[] :fetch

      yaml do
        map :managed_concept, to: :managed_concept
        map :managed_concepts_ids, to: :managed_concepts_ids
        map :concept_manager, to: :concept_manager
        map :store, to: :store
        map :fetch, to: :fetch
      end
      
      def managed_concepts
        @managed_concepts.values
      end

      def managed_concepts=(managed_concepts = [])
        managed_concepts.each do |managed_concept|
          store(Config.class_for(:managed_concept).new(managed_concept))
        end
  
        @managed_concepts.values
      end

      def each(&block)
        @managed_concepts.each_value(&block)
      end

      def fetch(id)
        @managed_concepts[id] || @managed_concepts[@managed_concepts_ids[id]]
      end

      def fetch_or_initialize(id)
        fetch(id) or store(Config.class_for(:managed_concept).new(data: { id: id }))
      end

      def store(managed_concept)
        @managed_concepts[managed_concept.uuid] = managed_concept
        @managed_concepts_ids[managed_concept.id] = managed_concept.uuid if managed_concept.id
  
        managed_concept
      end

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
