module Glossarist
  module LutamlModel
    module Designation
      class Symbol < Base
        attribute :international, :boolean
        attribute :type, :string

        yaml do
          map :international, to: :international
          map :type, to: :type, render_default: true
        end

        def self.of_yaml(hash, options = {})
          hash["type"] = "symbol" unless hash["type"]

          super
        end
      end
    end
  end
end
