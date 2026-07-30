# frozen_string_literal: true

module Glossarist
  module V3
    # GenericMember — one member (species) of a GenericHyperedge. The
    # `comprehensive` of its parent GenericHyperedge denotes the genus
    # concept; this member denotes one species.
    #
    # Per ISO 704:2022 §5.5.4.2.1, the intension of a species includes
    # the intension of the genus plus at least one additional
    # DELIMITING CHARACTERISTIC. Each species in a coordinate set
    # (siblings sharing the same criterion of subdivision) carries its
    # own delimiting characteristic value.
    #
    # Example (ISO 704 §5.5.4.2.1 Example 3):
    #   Hyperedge comprehensive: computer mouse
    #   Hyperedge criterion (of subdivision): means of movement detection
    #   Members:
    #     - mechanical mouse
    #       characteristic: "detecting movement by means of rollers"
    #     - optomechanical mouse
    #       characteristic: "detecting movement by means of rollers and light sensors"
    #     - optical mouse
    #       characteristic: "detecting movement by means of light sensors"
    #
    # Multidimensionality (ISO 704 §5.6.3): the same genus can have
    # multiple GenericHyperedges, each with a different criterion
    # (e.g., means of movement detection vs computer connection). The
    # `characteristic` on each member is meaningful only within its
    # parent hyperedge's criterion context.
    #
    # Distinct from PartitiveMember: partitive members are binary
    # delimiting (a part is or isn't delimiting); generic members are
    # textually delimiting (each species has its own characteristic
    # phrase that distinguishes it from coordinate concepts).
    class GenericMember < HyperedgeMember
      # The delimiting characteristic of this species under the parent
      # hyperedge's criterion of subdivision. Localized — different
      # languages may express the same characteristic differently.
      # Required for semantic completeness per ISO 704 §5.5.4.2.1, but
      # the model permits nil to allow incremental population.
      attribute :characteristic, :hash

      key_value do
        map :ref, to: :ref
        map :presence, to: :presence
        map :count, to: :count
        map :characteristic, to: :characteristic
      end
    end
  end
end
