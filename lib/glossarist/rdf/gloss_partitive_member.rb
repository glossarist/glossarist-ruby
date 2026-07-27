# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for V3::PartitiveMember. Emits a
    # gloss:PartitiveMember subject with ref, multiplicity, and
    # is_delimiting properties.
    class GlossPartitiveMember < Lutaml::Model::Serializable
      attribute :ref_id, :string
      attribute :ref_source, :string
      attribute :ref_text, :string
      attribute :multiplicity, :string
      attribute :is_delimiting, :boolean

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
        predicate :multiplicity, namespace: Namespaces::GlossaristNamespace,
                                 to: :multiplicity
        predicate :isDelimiting, namespace: Namespaces::GlossaristNamespace,
                                 to: :is_delimiting
      end
    end
  end
end
