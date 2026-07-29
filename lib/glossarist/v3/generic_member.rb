# frozen_string_literal: true

module Glossarist
  module V3
    # GenericMember — one member of a GenericRelation. Carries the same
    # MECE dimensions as PartitiveMember; the comprehensive of its
    # parent GenericRelation denotes the genus concept.
    #
    # See docs/design/generic-relation.md and docs/design/abstract-nary-relation.md
    # (concept-model repo).
    class GenericMember < ConceptSystemMember
      # Inherits all attributes and validations from ConceptSystemMember.
      # Declared as a distinct class for type safety and to leave room
      # for future generic-specific extensions.
    end
  end
end
