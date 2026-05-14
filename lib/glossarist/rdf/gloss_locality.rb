# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    class GlossLocality < Lutaml::Model::Serializable
      attribute :locality_type, :string
      attribute :reference_from, :string
      attribute :reference_to, :string

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |l| "locality/#{l.locality_type}/#{l.reference_from}" }

        types "gloss:Locality"

        predicate :localityType, namespace: Namespaces::GlossaristNamespace, to: :locality_type
        predicate :referenceFrom, namespace: Namespaces::GlossaristNamespace, to: :reference_from
        predicate :referenceTo, namespace: Namespaces::GlossaristNamespace, to: :reference_to
      end
    end
  end
end
