# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # Shared base for typed n-ary hyperedge member RDF views
    # (GlossPartitiveMember, GlossGenericMember, future leaves).
    #
    # Carries the shared attributes and the deterministic_id algorithm.
    # Concrete leaves declare their own `rdf do` block AND their own
    # type-specific attributes — `is_delimiting` on GlossPartitiveMember
    # (binary role, ISO 704 §5.5.4.2.2); `characteristic` on
    # GlossGenericMember (delimiting text, ISO 704 §5.5.4.2.1).
    #
    # Subject identity is content-derived so the same member in the
    # same hyperedge produces the same URI across runs (and across
    # processes). Two members with identical ref + dimensions share a
    # subject — that is intentional: it exposes model-level
    # inconsistency if the same concept is given different dimensions
    # inside the same dataset.
    class GlossNaryMember < Lutaml::Model::Serializable
      attribute :ref_id, :string
      attribute :ref_source, :string
      attribute :ref_text, :string
      attribute :presence, :string
      attribute :count, :string

      # Human-readable SOURCE:ID when both are present; SHA-256 / 16
      # hex chars fallback otherwise. Same content → same slug across
      # instances, runs, and processes.
      def self.deterministic_id(member)
        readable = [member.ref_source, member.ref_id].compact.reject(&:empty?)
        return readable.join(":") unless readable.empty?

        parts = [member.ref_source, member.ref_id, member.ref_text,
                 member.presence, member.count]
        # Type-specific discriminator: include the delimiting flag for
        # partitive members (binary role) or the characteristic text
        # for generic members (so members of different criteria don't
        # collide on the same hash input).
        case member
        when GlossPartitiveMember
          parts << member.is_delimiting
        when GlossGenericMember
          parts << member.characteristic
        end
        DeterministicSlug.from_parts(*parts)
      end
    end
  end
end
