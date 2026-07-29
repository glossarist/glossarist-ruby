# frozen_string_literal: true

module Glossarist
  module V3
    # HyperedgeIndex — derived reverse-lookup index over a flat list
    # of hyperedges.
    #
    # A hyperedge is directional: 1 comprehensive → N members. To
    # answer the reverse query ("which hyperedges is X a member of?"),
    # build a HyperedgeIndex on demand from the flat list and consult
    # #for_member. The index is NOT stored on the concept — it's a
    # derived view.
    #
    # Use cases:
    #   index.for_comprehensive("OIML:5.1")
    #     # => 6 hyperedges (different criteria — the OIML pattern)
    #   index.for_member("OIML:5.13")
    #     # => hyperedges where 5.13 appears as a member
    class HyperedgeIndex
      attr_reader :by_comprehensive, :by_member

      def initialize(hyperedges)
        @by_comprehensive = {}
        @by_member = {}

        Array(hyperedges).each do |h|
          register_comprehensive(h)
          register_members(h)
        end

        @by_comprehensive.freeze
        @by_member.freeze
      end

      # All hyperedges where the given concept is the comprehensive.
      # Accepts either a qualified-id string ("VIM:1.2") or a ConceptRef.
      def for_comprehensive(qualified_id_or_ref)
        key = resolve_key(qualified_id_or_ref)
        @by_comprehensive[key] || []
      end

      # All hyperedges where the given concept is one of the members.
      # Accepts either a qualified-id string or a ConceptRef.
      def for_member(qualified_id_or_ref)
        key = resolve_key(qualified_id_or_ref)
        @by_member[key] || []
      end

      # Every concept that appears anywhere in this hyperedge set
      # (as comprehensive OR as a member), with its roles.
      def all_concept_ids
        (@by_comprehensive.keys | @by_member.keys).freeze
      end

      private

      def register_comprehensive(hyperedge)
        return unless hyperedge.is_a?(AbstractHyperedge)

        key = Glossarist::ConceptRef.qualified_id(hyperedge.comprehensive)
        return unless key

        (@by_comprehensive[key] ||= []) << hyperedge
      end

      def register_members(hyperedge)
        return unless hyperedge.is_a?(AbstractHyperedge)

        Array(hyperedge.members).each do |m|
          next unless m.is_a?(HyperedgeMember)
          next unless m.ref.is_a?(Glossarist::ConceptRef)

          key = Glossarist::ConceptRef.qualified_id(m.ref)
          next unless key

          (@by_member[key] ||= []) << hyperedge
        end
      end

      def resolve_key(qualified_id_or_ref)
        if qualified_id_or_ref.is_a?(Glossarist::ConceptRef)
          Glossarist::ConceptRef.qualified_id(qualified_id_or_ref)
        else
          qualified_id_or_ref.to_s
        end
      end
    end
  end
end
