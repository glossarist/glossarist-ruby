# frozen_string_literal: true

module Glossarist
  module V3
    # PartitiveRelation — an ISO 704 / ISO 1087-1 / ISO 12620
    # partitive relation connecting a comprehensive concept
    # (superordinate concept partitive) to two or more partitive
    # concepts (subordinate concepts partitive) which fitted together
    # constitute the comprehensive.
    #
    # Inherits structure and validations from AbstractNaryRelation.
    # The `comprehensive` field denotes the whole concept.
    #
    # Wire field `members` is uniform across all n-ary relation types
    # (was: `partitives` — renamed in the v3 clean break).
    #
    # Per-file storage: lives at
    # relations/<comprehensive-id>/<criterion-slug>.yaml — see
    # docs/design/relations-as-files.md (concept-model repo).
    class PartitiveRelation < AbstractNaryRelation
      attribute :members, PartitiveMember, collection: true

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
