# frozen_string_literal: true

module Glossarist
  class Concept < Model
    attribute :termid, :string

    alias :id :termid

    # attribute :superseded_concepts # TODO

    attribute :localizations, default: {}

    def to_h
      h = super
      h.merge(h.delete("localizations"))
    end
  end
end
