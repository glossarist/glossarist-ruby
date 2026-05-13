module Glossarist
  module Designation
    class LetterSymbol < Symbol
      attribute :text, :string

      key_value do
        map :text, to: :text
      end

      def self.of_yaml(hash, options = {})
        hash["type"] = "letter_symbol"

        super
      end
    end
  end
end
