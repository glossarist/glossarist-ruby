# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    class GlossNonVerbalRep < Lutaml::Model::Serializable
      attribute :representation_type, :string
      attribute :representation_ref, :string
      attribute :representation_text, :string
      attribute :sources, GlossConceptSource, collection: true
      attribute :concept_id, :string
      attribute :lang_code, :string
      attribute :index, :string

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |n| "concept/#{n.concept_id}/#{n.lang_code}/nonverbal/#{n.index}" }

        types "gloss:NonVerbalRepresentation"

        predicate :representationType, namespace: Namespaces::GlossaristNamespace, to: :representation_type
        predicate :representationRef, namespace: Namespaces::GlossaristNamespace, to: :representation_ref
        predicate :representationText, namespace: Namespaces::GlossaristNamespace, to: :representation_text

        members :sources
      end
    end
  end
end
