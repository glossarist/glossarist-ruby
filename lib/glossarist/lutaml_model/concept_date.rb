# frozen_string_literal: true

module Glossarist
  module LutamlModel
    class ConceptDate < Lutaml::Model::Serializable
      # Iso8601 date
      # @return [String]
      attribute :date, :date_time
      attribute :type, :string, values: Glossarist::GlossaryDefinition::CONCEPT_DATE_TYPES

      yaml do
        map :date, to: :date
        map :type, to: :type
      end
    end
  end
end
