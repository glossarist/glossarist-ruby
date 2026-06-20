# frozen_string_literal: true

module Glossarist
  class DetailedDefinition < Lutaml::Model::Serializable
    attribute :content, :string
    attribute :sources, ConceptSource, collection: true
    attribute :examples, DetailedDefinition, collection: true, initialize_empty: true

    key_value do
      map :content, to: :content
      map :sources, to: :sources
      map :examples, to: :examples
    end
  end
end
