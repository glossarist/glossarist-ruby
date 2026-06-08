# frozen_string_literal: true

module Glossarist
  module Designation
    class DesignationRelationship < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :type, :string,
                values: Glossarist::GlossaryDefinition::DESIGNATION_RELATIONSHIP_TYPES
      attribute :target, :string

      key_value do
        map :content, to: :content
        map :type, to: :type
        map :target, to: :target
      end
    end
  end
end
