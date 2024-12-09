require_relative "symbol"

module Glossarist
  module LutamlModel
    class GraphicalSymbol < Symbol
      attribute :text, :string
      attribute :image, :string

      yaml do
        map :text, to: :text
        map :image, to: :image
      end
    end
  end
end
