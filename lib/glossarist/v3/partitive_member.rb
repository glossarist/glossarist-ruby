# frozen_string_literal: true

module Glossarist
  module V3
    # PartitiveMember — one member of a PartitiveHyperedge. The
    # `comprehensive` of its parent PartitiveHyperedge denotes the
    # whole concept; this member denotes one of its parts.
    #
    # Per ISO 704:2022 §5.5.4.2.2, a part is either delimiting or not:
    # a delimiting part behaves like a delimiting characteristic — it
    # distinguishes the comprehensive (whole) from coordinate concepts.
    # Example: for "optomechanical mouse", the delimiting parts are
    # mouse ball, x/y-axis rollers, infrared emitter/sensor — they
    # distinguish it from "mechanical mouse" and "optical mouse".
    # Mouse button is NOT delimiting (all computer mice have buttons).
    #
    # The binary role is sufficient — no per-member delimiting text is
    # needed because the part itself IS the delimiting marker.
    class PartitiveMember < HyperedgeMember
      attribute :is_delimiting, :boolean, default: -> { false }

      key_value do
        map :ref, to: :ref
        map :presence, to: :presence
        map :count, to: :count
        map :is_delimiting, to: :is_delimiting
      end

      def delimiting?
        is_delimiting == true
      end
    end
  end
end
