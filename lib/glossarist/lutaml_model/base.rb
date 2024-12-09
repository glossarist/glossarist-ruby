module Glossarist
  module LutamlModel
    class Base < Lutaml::Model::Serializable
      attribute :designation, :string
      attribute :geographical_area, :string
      attribute :normative_status, :string, values: Glossarist::GlossaryDefinition::DESIGNATION_BASE_NORMATIVE_STATUSES
      attribute :type, :string

      yaml do
        map :designation, to: :designation
        map :geographical_area, to: :geographical_area
        map :normative_status, to: :normative_status
        map :type, to: :type
      end
    end
  end
end
