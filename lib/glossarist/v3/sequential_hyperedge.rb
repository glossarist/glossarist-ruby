# frozen_string_literal: true

module Glossarist
  module V3
    # SequentialHyperedge — an ISO 12620 A.6.3 / ISO 704:2022 §5.5.5
    # sequential relation connecting a comprehensive concept to two or
    # more subordinate concepts in an ORDERED sequence (temporal,
    # spatial, causal, developmental).
    #
    # Mirror of PartitiveHyperedge and GenericHyperedge. Members are
    # ORDERED — array order is significant. Reversing the array
    # reverses the sequence.
    class SequentialHyperedge < AbstractHyperedge
      WIRE_KEY = "sequential_relations"
      TYPE_TAG = "sequential_relation"
      RDF_TYPE = "gloss:SequentialRelation"
      V1_WIRE_KEYS = [].freeze

      attribute :members, SequentialMember, collection: true

      key_value do
        map :comprehensive, to: :comprehensive
        map :members, to: :members
        map :completeness, to: :completeness
        map :criterion, to: :criterion
        map :sources, to: :sources
        map :notes, to: :notes
        map :status, to: :status
      end

      HyperedgeRegistry.register(SequentialHyperedge)
    end
  end
end
