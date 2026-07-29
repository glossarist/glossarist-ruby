# frozen_string_literal: true

module Glossarist
  module V3
    # GenericHyperedge — an ISO 704 / ISO 1087-1 / ISO 12620 generic
    # hyperedge connecting a comprehensive concept (the genus) to two
    # or more specific concepts (the species) which together
    # constitute a decomposition by some criterion of subdivision.
    #
    # Mirror of PartitiveHyperedge. The `comprehensive` field denotes
    # the genus concept. Multiple GenericHyperedges on the same
    # comprehensive distinguished by `criterion` is the OIML pattern
    # (5.1 measurement standard has 6 criterion groups).
    #
    # See docs/design/generic-relation.md (concept-model repo).
    #
    # The `key_value` mapping is inherited from AbstractHyperedge
    # (single SSOT). Only the typed member collection is narrowed here.
    #
    # Per-class metadata block — see PartitiveHyperedge for field docs.
    class GenericHyperedge < AbstractHyperedge
      WIRE_KEY     = "generic_relations"
      TYPE_TAG     = "generic_relation"
      RDF_TYPE     = "gloss:GenericRelation"
      MEMBER_CLASS = GenericMember
      V1_WIRE_KEYS = [].freeze
      KIND_LABEL   = "GEN"

      attribute :members, GenericMember, collection: true
    end

    HyperedgeRegistry.register(GenericHyperedge)
  end
end
