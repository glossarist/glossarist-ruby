# frozen_string_literal: true

module Glossarist
  # A reference from a concept to a dataset-level Formula entity.
  #
  # Produced by `formulas: [id]` structural arrays and `{{formula:id}}` inline
  # mentions.
  class FormulaReference < NonVerbalReference
    key_value do
      map :entity_id, to: :entity_id
      map :display, to: :display
    end
  end
end
