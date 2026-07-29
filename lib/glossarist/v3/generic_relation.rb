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
    class GenericRelation < AbstractNaryRelation
      attribute :members, GenericMember, collection: true

      key_value do
        map :comprehensive, to: :comprehensive
        map :members, to: :members
        map :completeness, to: :completeness
        map :criterion, to: :criterion
        map :sources, to: :sources
        map :notes, to: :notes
        map :status, to: :status
      end
    end
  end
end
