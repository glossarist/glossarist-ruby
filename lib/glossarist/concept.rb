# frozen_string_literal: true

module Glossarist
  class Concept < Model
    attribute :termid, :string

    alias :id :termid

    # attribute :superseded_concepts # TODO

    attribute :localizations, default: {}

    def attributes
      {
        "termid" => termid,
        "term" => localizations["eng"].terms&.dig(0, "designation"),
        **localizations.to_h
      }
      # require
      # {

      # super.merge
      # }
    end

    # def to_h
    #   attributes
    # end

    # def to_h
    #   h = super
    #   translations =
    #   h.merge(h.delete("localizations").transform_values(&:to_h))
    # end
  end
end
