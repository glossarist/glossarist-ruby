require_relative "symbol"

module Glossarist
  module Designation
    class GraphicalSymbol < Symbol
      attribute :text, :string
      attribute :image, :string

      key_value do
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
