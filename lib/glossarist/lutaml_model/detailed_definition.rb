# frozen_string_literal: true

module Glossarist
  module LutamlModel
    class DetailedDefinition < Lutaml::Model::Serializable
      def initialize(attributes = {})
        attributes = { content: attributes } unless attributes.is_a?(Hash)

        super(attributes)
      end

      attribute :content, :string
      attribute :sources, ConceptSource, collection: true

      yaml do
        map :content, to: :content
        map :sources, to: :sources
      end

      def self.as_yaml(instance)
        hash_rep = super

        hash_rep.delete("sources") if instance.sources.empty?

        hash_rep
      end
    end
  end
end
