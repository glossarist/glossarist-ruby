# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    class GlossConceptReference < Lutaml::Model::Serializable
      attribute :term, :string
      attribute :concept_id, :string
      attribute :source, :string
      attribute :ref_type, :string
      attribute :urn, :string
      attribute :parent_id, :string

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |r| "concept/#{r.parent_id}/ref/#{r.concept_id || r.urn}" }

        types "gloss:ConceptReference"

        predicate :refType, namespace: Namespaces::GlossaristNamespace, to: :ref_type
        predicate :conceptId, namespace: Namespaces::GlossaristNamespace, to: :concept_id
        predicate :sourceUri, namespace: Namespaces::GlossaristNamespace, to: :source
        predicate :urn, namespace: Namespaces::GlossaristNamespace, to: :urn
      end
    end
  end
end
