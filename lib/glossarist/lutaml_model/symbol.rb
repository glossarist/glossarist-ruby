module Glossarist
  module LutamlModel
    class Symbol < Base
      attribute :international, :boolean
      attribute :type, :string, default: -> { "symbol" }

      yaml do
        map :international, to: :international
        map :type, to: :type, render_default: true
      end
    end
  end
end
