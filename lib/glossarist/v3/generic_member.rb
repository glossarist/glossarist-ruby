# frozen_string_literal: true

module Glossarist
  module V3
    # GenericMember — one member of a GenericHyperedge. Carries the same
    # MECE dimensions as PartitiveMember; the comprehensive of its
    # parent GenericHyperedge denotes the genus concept.
    #
    # See docs/design/generic-relation.md and docs/design/abstract-nary-relation.md
    # (concept-model repo).
    class GenericMember < HyperedgeMember
      # Inherits all attributes and validations from HyperedgeMember.
      # Declared as a distinct class for type safety and to leave room
      # for future generic-specific extensions.
    end
  end
end
