# frozen_string_literal: true

module Glossarist
  # A reference from a concept to a dataset-level Figure entity.
  #
  # Produced by `figures: [id]` structural arrays and `{{fig:id}}` inline
  # mentions. Both forms resolve through the same figure adapter.
  class FigureReference < NonVerbalReference
    key_value do
      map :entity_id, to: :entity_id
      map :display, to: :display
    end
  end
end
