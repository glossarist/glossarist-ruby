# frozen_string_literal: true

module Glossarist
  module V3
    # GenericRelation — an ISO 704 / ISO 1087-1 / ISO 12620 generic
    # relation connecting a comprehensive concept (the genus) to two
    # or more specific concepts (the species) which together
    # constitute a decomposition by some criterion of subdivision.
    #
    # Mirror of PartitiveRelation. The `comprehensive` field denotes
    # the genus concept. Multiple GenericRelations on the same
    # comprehensive distinguished by `criterion` is the OIML pattern
    # (5.1 measurement standard has 6 criterion groups).
    #
    # See docs/design/generic-relation.md (concept-model repo).
    #
    # The `key_value` mapping is inherited from AbstractNaryRelation
    # (single SSOT). Only the typed member collection is narrowed
    # here.
    class GenericRelation < AbstractNaryRelation
      attribute :members, GenericMember, collection: true
    end
  end
end
