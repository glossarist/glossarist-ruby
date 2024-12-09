module Glossarist
  module LutamlModel
    class LetterSymbol < Symbol
      attribute :text, :string
      attribute :language, :string
      attribute :script, :string

      yaml do
        map :text, to: :text
        map :language, to: :language
        map :script, to: :script
      end
    end
  end
end
