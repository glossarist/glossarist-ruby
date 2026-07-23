# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for V3::PartitiveRelation. Emits a
    # gloss:PartitiveRelation subject with comprehensive, hasPartitive,
    # completeness, hasPlurality, criterion properties.
    class GlossPartitiveRelation < Lutaml::Model::Serializable
      attribute :identifier, :string
      attribute :comprehensive_uri, :string
      attribute :partitive_member_ids, :string, collection: true
      attribute :completeness, :string
      attribute :has_plurality, GlossTypeSharedPlurality
      attribute :criterion, :hash

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |r| "partitiveRelation/#{r.identifier}/#{r.object_id}" }

        types "gloss:PartitiveRelation"

        predicate :comprehensive, namespace: Namespaces::GlossaristNamespace,
                                  to: :comprehensive_uri, uri_reference: true
        predicate :hasPartitive, namespace: Namespaces::GlossaristNamespace,
                                 to: :partitive_member_ids, uri_reference: true
        predicate :completeness, namespace: Namespaces::GlossaristNamespace,
                                 to: :completeness, uri_reference: true
        members :has_plurality,
                link: "gloss:hasPlurality"
        predicate :criterion, namespace: Namespaces::GlossaristNamespace,
                              to: :criterion
      end
    end
  end
end
