module Glossarist
  module LutamlModel
    module Designation
      class LetterSymbol < Symbol
        attribute :text, :string
        attribute :language, :string
        attribute :script, :string

        yaml do
          map :text, to: :text
          map :language, to: :language
          map :script, to: :script
        end

        def self.of_yaml(hash, options = {})
          hash["type"] = "letter_symbol"

          super
        end
      end
    end
  end
end
