# frozen_string_literal: true

module Glossarist
  module V3
    # V3 variant of ConceptDate. The base {Glossarist::ConceptDate} types
    # `date` as `:date_time` (ISO 8601 datetime only), but the v3 schema
    # (`concept-model/schemas/v3/concept.yaml`) declares
    #
    #   concept_date:
    #     properties:
    #       date:
    #         type: string
    #         format: date
    #
    # which accepts any date string — full ISO 8601 datetime ("2023-01-01T00:00:00+00:00"),
    # calendar date ("2023-01-01"), or year-only ("2023"). Datasets such as
    # the IALA Dictionary (datasets/iala-*/concepts/*.yaml) use year-only
    # strings for accepted/retired lifecycle markers, so the v3 model needs
    # to round-trip those without losing the value.
    #
    # See BUG_REPORT.md for the full investigation.
    class ConceptDate < Glossarist::ConceptDate
      attribute :date, :string

      key_value do
        map :date, to: :date
        map :type, to: :type
      end
    end
  end
end
