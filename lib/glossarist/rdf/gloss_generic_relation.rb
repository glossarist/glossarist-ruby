# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for V3::GenericRelation. Emits a gloss:GenericRelation
    # subject with comprehensive, completeness, criterion properties,
    # plus hasGenericMember (typed subjects carrying the ISO 704:2022
    # per-member dimensions).
    #
    # Mirror of GlossPartitiveRelation. The split exists because the
    # gloss:PartitiveRelation vs gloss:GenericRelation type is part of
    # the RDF vocabulary — SPARQL queries that filter by type can
    # then discriminate genus/species from whole/parts decompositions.
    class GlossGenericRelation < Lutaml::Model::Serializable
      attribute :identifier, :string
      attribute :comprehensive_uri, :string
      attribute :generic_member_ids, :string, collection: true
      attribute :generic_members, GlossGenericMember, collection: true
      attribute :completeness, :string
      attribute :criterion, :hash

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |r| "genericRelation/#{GlossGenericRelation.deterministic_id(r)}" }

        types "gloss:GenericRelation"

        predicate :comprehensive, namespace: Namespaces::GlossaristNamespace,
                                  to: :comprehensive_uri, uri_reference: true
        predicate :hasGeneric, namespace: Namespaces::GlossaristNamespace,
                               to: :generic_member_ids, uri_reference: true
        predicate :completeness, namespace: Namespaces::GlossaristNamespace,
                                 to: :completeness, uri_reference: true
        predicate :criterion, namespace: Namespaces::GlossaristNamespace,
                              to: :criterion

        members :generic_members, link: "gloss:hasGenericMember"
      end

      def self.deterministic_id(rel)
        parts = [rel.identifier, rel.comprehensive_uri, rel.completeness,
                 criterion_fingerprint(rel.criterion)]
        Array(rel.generic_members).each do |m|
          parts << GlossGenericMember.deterministic_id(m)
        end
        DeterministicSlug.from_parts(*parts)
      end

      def self.criterion_fingerprint(criterion)
        return nil unless criterion.is_a?(Hash) && !criterion.empty?

        criterion.sort_by { |k, _| k.to_s }
          .map { |k, v| "#{k}=#{v}" }
          .join(";")
      end
    end
  end
end
