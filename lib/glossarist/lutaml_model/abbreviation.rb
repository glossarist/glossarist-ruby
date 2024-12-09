module Glossarist
  module LutamlModel
    class Abbreviation < Expression
      attribute :international, :string
      attribute :type, :string, default: -> { "abbreviation" }, values: Glossarist::GlossaryDefinition::ABBREVIATION_TYPES

      yaml do
        map :international, to: :international
        map :type, to: :type, render_default: true
      end
    end
  end
end
