module Glossarist
  module LutamlModel
    class Abbreviation < Lutaml::Model::Serializable
      attribute :international, :string
      attribute :type, :string, default: -> { "abbreviation" }, values: Glossarist::GlossaryDefinition::ABBREVIATION_TYPES
      attribute :expression, Expression

      yaml do
        map :international, to: :international
        map :type, to: :type, render_default: true
        map :expression, to: :expression
      end
    end
  end
end
