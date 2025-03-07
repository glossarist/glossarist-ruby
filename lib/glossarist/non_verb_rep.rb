module Glossarist
  class NonVerbRep < Lutaml::Model::Serializable
    attribute :image, :string
    attribute :table, :string
    attribute :formula, :string
    attribute :sources, ConceptSource, collection: true, initialize_empty: true

    yaml do
      map :image, to: :image
      map :table, to: :table
      map :formula, to: :formula
      map :sources, to: :sources
    end
  end
end
