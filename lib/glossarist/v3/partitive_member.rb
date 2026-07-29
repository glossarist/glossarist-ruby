# frozen_string_literal: true

module Glossarist
  module V3
    # PartitiveMember — one member of a PartitiveHyperedge. Inherits
    # the ISO 704:2022 MECE shape from HyperedgeMember; the
    # `comprehensive` of its parent PartitiveHyperedge denotes the
    # whole concept.
    #
    # Distinct leaf class for type safety and to leave room for
    # partitive-specific extensions if needed.
    class PartitiveMember < HyperedgeMember
      # Inherits all attributes and validations from HyperedgeMember.
    end
  end
end
