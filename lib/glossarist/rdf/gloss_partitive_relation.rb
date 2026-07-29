# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for V3::PartitiveHyperedge. Inherits structure and
    # helpers from GlossNaryRelation. The `rdf do` block re-declares
    # the predicates because lutaml-model's `rdf` DSL replaces the
    # parent mapping (not extends).
    class GlossPartitiveRelation < GlossNaryRelation
      attribute :partitive_member_ids, :string, collection: true
      attribute :partitive_members, GlossPartitiveMember, collection: true

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |r| "partitiveRelation/#{GlossPartitiveRelation.deterministic_id(r)}" }

        types "gloss:PartitiveHyperedge"

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
        parts = [rel.identifier, rel.comprehensive_uri, rel.completeness,
                 criterion_fingerprint(rel.criterion)]
        Array(rel.partitive_members).each do |m|
          parts << GlossPartitiveMember.deterministic_id(m)
        end
        DeterministicSlug.from_parts(*parts)
      end
    end
  end
end
