module Glossarist
  class NonVerbRep < Lutaml::Model::Serializable
    attribute :image, :string
    attribute :table, :string
    attribute :formula, :string
    attribute :sources, ConceptSource, collection: true

    key_value do
      map :image, to: :image
      map :table, to: :table
      map :formula, to: :formula
      map :sources, to: :sources
    end
  end
end
