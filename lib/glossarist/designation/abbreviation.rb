module Glossarist
  module Designation
    class Abbreviation < Expression
      attribute :international, :boolean
      attribute :type, :string, default: -> { "abbreviation" }

      Glossarist::GlossaryDefinition::ABBREVIATION_TYPES.each do |name|
        attribute name.to_sym, :boolean
      end

      yaml do
        map :international, to: :international
        map :type, to: :type, render_default: true
        Glossarist::GlossaryDefinition::ABBREVIATION_TYPES.each do |name|
          map name.to_sym, to: name.to_sym
        end
      end

      def self.of_yaml(hash, options = {})
        hash["type"] = "abbreviation" unless hash["type"]

        super
      end
    end
  end
end
