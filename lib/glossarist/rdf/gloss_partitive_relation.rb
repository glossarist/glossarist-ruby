# frozen_string_literal: true

require "digest"
require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for V3::PartitiveRelation. Emits a
    # gloss:PartitiveRelation subject with comprehensive, completeness,
    # criterion properties, plus hasPartitive (concept URIs, for graph
    # traversal) and hasPartitiveMember (typed subjects carrying the
    # ISO 704:2022 per-member dimensions).
    class GlossPartitiveRelation < Lutaml::Model::Serializable
      attribute :identifier, :string
      attribute :comprehensive_uri, :string
      attribute :partitive_member_ids, :string, collection: true
      attribute :partitive_members, GlossPartitiveMember, collection: true
      attribute :completeness, :string
      attribute :criterion, :hash

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |r| "partitiveRelation/#{GlossPartitiveRelation.deterministic_id(r)}" }

        types "gloss:PartitiveRelation"

        predicate :comprehensive, namespace: Namespaces::GlossaristNamespace,
                                  to: :comprehensive_uri, uri_reference: true
        predicate :hasPartitive, namespace: Namespaces::GlossaristNamespace,
                                 to: :partitive_member_ids, uri_reference: true
        predicate :completeness, namespace: Namespaces::GlossaristNamespace,
                                 to: :completeness, uri_reference: true
        predicate :criterion, namespace: Namespaces::GlossaristNamespace,
                              to: :criterion

        members :partitive_members, link: "gloss:hasPartitiveMember"
      end

      def self.deterministic_id(rel)
        parts = [rel.identifier, rel.comprehensive_uri, rel.completeness]
        parts << criterion_fingerprint(rel.criterion)
        Array(rel.partitive_members).each do |m|
          parts << GlossPartitiveMember.deterministic_id(m)
        end
        Digest::MD5.hexdigest(parts.compact.join("|"))[0..11]
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
