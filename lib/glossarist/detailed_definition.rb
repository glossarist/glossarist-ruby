# frozen_string_literal: true

module Glossarist
  class DetailedDefinition < Lutaml::Model::Serializable
    attribute :content, :string
    attribute :sources, ConceptSource, collection: true

    yaml do
      map :content, to: :content
      map :sources, to: :sources
    end
  end
end
