# frozen_string_literal: true

module Glossarist
  # A reference from a concept to a dataset-level Table entity.
  #
  # Produced by `tables: [id]` structural arrays and `{{table:id}}` inline
  # mentions.
  class TableReference < NonVerbalReference
    key_value do
      map :entity_id, to: :entity_id
      map :display, to: :display
    end
  end
end
