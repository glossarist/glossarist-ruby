# frozen_string_literal: true

module Glossarist
  class ConceptDate < Lutaml::Model::Serializable
    # Iso8601 date
    # @return [String]
    attribute :date, :date_time
    attribute :type, :string,
              values: Glossarist::GlossaryDefinition::CONCEPT_DATE_TYPES

    key_value do
      map :date, to: :date
      map :type, to: :type
    end

    # Returns the date as a string for flat YAML fields such as
    # ManagedConcept#date_accepted. Subclasses whose `date` is not a
    # DateTime override this so callers do not need to type-check.
    def to_yaml_date
      date&.iso8601
    end
  end
end
