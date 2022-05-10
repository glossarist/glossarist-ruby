# frozen_string_literal: true

module Glossarist
  class ConceptDate < Model
    include Glossarist::Utilities::Enum

    # Iso8601 date
    # @return [String]
    attr_accessor :date

    register_enum :type, Glossarist::GlossaryDefinition::CONCEPT_DATE_TYPES

    def to_h
      {
        "date" => date,
        "type" => type,
      }.compact
    end
  end
end
