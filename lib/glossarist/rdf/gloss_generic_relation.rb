# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for V3::GenericHyperedge. Inherits structure and
    # helpers from GlossNaryRelation. The `rdf do` block re-declares
    # the predicates because lutaml-model's `rdf` DSL replaces the
    # parent mapping (not extends).
    class GlossGenericRelation < GlossNaryRelation
      attribute :generic_member_ids, :string, collection: true
      attribute :generic_members, GlossGenericMember, collection: true

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |r| "genericRelation/#{GlossGenericRelation.deterministic_id(r)}" }

        types "gloss:GenericHyperedge"

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
    end
  end
end
