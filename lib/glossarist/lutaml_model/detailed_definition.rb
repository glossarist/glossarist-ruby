# frozen_string_literal: true

module Glossarist
  module LutamlModel
    class DetailedDefinition < Lutaml::Model::Serializable
      # @return [Array<ConceptSource>]
      # attr_reader :sources
      attribute :content, :string
      attribute :sources, ConceptSource, collection: true

      yaml do
        map :content, to: :content
        map :sources, to: :sources
      end
    end
  end
end
