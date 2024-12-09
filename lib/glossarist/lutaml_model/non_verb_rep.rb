module Glossarist
  module LutamlModel
    class NonVerbRep < Lutaml::Model::Serializable
      attribute :image, :string
      attribute :table, :string
      attribute :formula, :string
      attribute :sources, ConceptSource, collection: true

      yaml do
        map :image, to: :image
        map :table, to: :table
        map :formula, to: :formula
        map :sources, to: :sources
      end
    end
  end
end
