# frozen_string_literal: true

module Glossarist
  module V3
    # SequentialMember — one member of a SequentialHyperedge. Inherits
    # the MECE shape from HyperedgeMember.
    #
    # Distinct leaf class for type safety. The member's POSITION IN THE
    # ARRAY is significant for sequential hyperedges (unlike partitive
    # and generic where order is insignificant).
    class SequentialMember < HyperedgeMember
      # Inherits all attributes and validations from HyperedgeMember.
    end
  end
end
