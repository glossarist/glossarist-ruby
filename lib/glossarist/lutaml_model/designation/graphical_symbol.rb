require_relative "symbol"

module Glossarist
  module LutamlModel
    module Designation
      class GraphicalSymbol < Symbol
        attribute :text, :string
        attribute :image, :string

        yaml do
          map :text, to: :text
          map :image, to: :image
        end

        def self.of_yaml(hash, options = {})
          hash["type"] = "graphical_symbol"

          super
        end
      end
    end
  end
end
