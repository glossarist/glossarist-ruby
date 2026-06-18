# frozen_string_literal: true

module Glossarist
  # A concept-local non-verbal representation (ISO 10241-1 §6.5).
  #
  # NonVerbRep is the inline form attached directly to a concept's data.
  # The dataset-shared form is Figure / Table / Formula. The two share the
  # same a11y + provenance payload via NonVerbalEntity; NonVerbRep differs
  # only in that it has no dataset-wide identity (no +id+, no +identifier+)
  # — its identity is its position inside the parent concept.
  #
  # +type+ discriminates the kind of non-verbal content: "image", "table",
  # or "formula". When +type+ is "image", +images+ carries one or more
  # FigureImage variants (responsive, format fallback, dark/light). The
  # caption/description/alt fields are localized (hash keyed by ISO 639
  # code) for accessibility.
  class NonVerbRep < NonVerbalEntity
    attribute :type, :string
    attribute :images, FigureImage, collection: true, initialize_empty: true

    key_value do
      map :type, to: :type
      map :images, to: :images
    end
  end
end
