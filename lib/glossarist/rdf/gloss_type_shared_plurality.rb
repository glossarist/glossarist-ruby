# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for V3::TypeSharedPlurality. Emits a
    # gloss:TypeSharedPlurality subject with is_shared, is_uncertain,
    # shared_type properties.
    class GlossTypeSharedPlurality < Lutaml::Model::Serializable
      attribute :is_shared, :boolean
      attribute :is_uncertain, :boolean
      attribute :shared_type_uri, :string

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |p| "plurality/#{p.object_id}" }

        types "gloss:TypeSharedPlurality"

        predicate :isShared, namespace: Namespaces::GlossaristNamespace,
                             to: :is_shared
        predicate :isUncertain, namespace: Namespaces::GlossaristNamespace,
                                to: :is_uncertain
        predicate :sharedType, namespace: Namespaces::GlossaristNamespace,
                               to: :shared_type_uri, uri_reference: true
      end
    end
  end
end
