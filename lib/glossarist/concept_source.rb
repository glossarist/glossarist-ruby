# frozen_string_literal: true

module Glossarist
  class ConceptSource < Model
    include Glossarist::Utilities::Enum

    register_enum :status, Glossarist::GlossaryDefinition::CONCEPT_SOURCE_STATUSES
    register_enum :type, Glossarist::GlossaryDefinition::CONCEPT_SOURCE_TYPES

    attr_accessor :origin
    attr_accessor :modification

    def to_h
      {
        "type" => type.to_s,
        "status" => status.to_s,
        "origin" => origin,
        "modification" => modification,
      }
    end
  end
end
