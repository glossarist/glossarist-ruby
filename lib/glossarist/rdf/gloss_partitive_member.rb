# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for V3::PartitiveMember. Emits a
    # gloss:PartitiveMember subject with ref + certainty properties.
    class GlossPartitiveMember < Lutaml::Model::Serializable
      attribute :ref_id, :string
      attribute :ref_source, :string
      attribute :ref_text, :string
      attribute :certainty, :string

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |m| "partitiveMember/#{m.ref_source}:#{m.ref_id}" }

        types "gloss:PartitiveMember"

        predicate :refSource, namespace: Namespaces::GlossaristNamespace,
                              to: :ref_source
        predicate :refId, namespace: Namespaces::GlossaristNamespace,
                          to: :ref_id
        predicate :refText, namespace: Namespaces::GlossaristNamespace,
                            to: :ref_text
        predicate :certainty, namespace: Namespaces::GlossaristNamespace,
                              to: :certainty
      end
    end
  end
end
