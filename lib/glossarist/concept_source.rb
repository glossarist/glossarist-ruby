# frozen_string_literal: true

module Glossarist
  class ConceptSource < Model
    include Glossarist::Utilities::Enum

    STATUSES = %i[
      identical
      modified
      restyle
      context-added
      generalisation
      specialisation
      unspecified
    ]

    TYPES = %i[
      authoritative
      lineage
    ]

    register_enum :status, STATUSES
    register_enum :type, TYPES

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
