module Glossarist
  module LutamlModel
    class LetterSymbol < Lutaml::Model::Serializable
      attribute :text, :string
      attribute :language, :string
      attribute :script, :string
      attribute :symbol, Symbol

      yaml do
        map :text, to: :text
        map :language, to: :language
        map :script, to: :script
        map :symbol, to: :symbol
      end
    end
  end
end
