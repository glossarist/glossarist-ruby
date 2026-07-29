# frozen_string_literal: true

module Glossarist
  module V3
    # PartitiveMember — one member of a PartitiveRelation. Inherits
    # the ISO 704:2022 MECE shape from ConceptSystemMember; the
    # `comprehensive` of its parent PartitiveRelation denotes the
    # whole concept.
    #
    # Distinct leaf class for type safety and to leave room for
    # partitive-specific extensions if needed.
    class PartitiveMember < ConceptSystemMember
      # Inherits all attributes and validations from ConceptSystemMember.
    end
  end
end
