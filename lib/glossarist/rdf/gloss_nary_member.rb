# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # Shared base for typed n-ary relation member RDF views
    # (GlossPartitiveMember, GlossGenericMember, future leaves).
    #
    # Carries the shared attributes and the deterministic_id algorithm.
    # Concrete leaves declare their own `rdf do` block because
    # lutaml-model's `rdf` DSL replaces (not extends) the parent's
    # mapping — predicate declarations stay in each leaf.
    #
    # Subject identity is content-derived so the same member in the
    # same relation produces the same URI across runs (and across
    # processes). Two members with identical ref + dimensions share a
    # subject — that is intentional: it exposes model-level
    # inconsistency if the same partitive concept is given different
    # dimensions inside the same dataset.
    class GlossNaryMember < Lutaml::Model::Serializable
      attribute :ref_id, :string
      attribute :ref_source, :string
      attribute :ref_text, :string
      attribute :presence, :string
      attribute :count, :string
      attribute :is_delimiting, :boolean

      # Human-readable SOURCE:ID when both are present; SHA-256 / 16
      # hex chars fallback otherwise. Same content → same slug across
      # instances, runs, and processes.
      def self.deterministic_id(member)
        readable = [member.ref_source, member.ref_id].compact.reject(&:empty?)
        return readable.join(":") unless readable.empty?

        DeterministicSlug.from_parts(
          member.ref_source, member.ref_id, member.ref_text,
          member.presence, member.count, member.is_delimiting
        )
      end
    end
  end
end
