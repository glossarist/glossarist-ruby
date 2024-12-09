module Glossarist
  module LutamlModel
    class GraphicalSymbol < Lutaml::Model::Serializable
      attribute :text, :string
      attribute :image, :string
      attribute :symbol, Symbol

      yaml do
        map :text, to: :text
        map :image, to: :image
        map :symbol, to: :symbol
      end
    end
  end
end
