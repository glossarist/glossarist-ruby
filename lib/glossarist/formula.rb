# frozen_string_literal: true

module Glossarist
  # A dataset-level formula entity (ISO 10241-1 §6.5 — non-verbal representation).
  #
  # Formulas are authored at `datasets/{ds}/formulas/{formula-id}.yaml` and
  # shared across concepts. The mathematical expression is stored in a
  # notation format (LaTeX, MathML, AsciiMath). Caption, description, and
  # alt are localized for accessibility.
  class Formula < NonVerbalEntity
    attribute :expression, :hash
    attribute :notation, :string

    key_value do
      map :id, to: :id
      map :identifier, to: :identifier
      map :caption, to: :caption
      map :description, to: :description
      map :alt, to: :alt
      map :expression, to: :expression
      map :notation, to: :notation
      map :sources, to: :sources
    end
  end
end
