# frozen_string_literal: true

module Glossarist
  class Concept < Model
    attribute :id, :string

    # attribute :superseded_concepts # TODO

    attribute :localizations, default: []
  end
end
