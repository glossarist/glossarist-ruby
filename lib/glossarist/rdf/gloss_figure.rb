# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for a dataset-level Figure entity (concept-model v3.1.0 K1).
    #
    # Emits a `gloss:Figure` subject with:
    #   - gloss:image — xsd:anyURI (the first image variant's src)
    #   - gloss:caption — xsd:string (one language picked from the localized hash)
    #   - dcterms:description — xsd:string (one language picked)
    #
    # The Figure domain model (Glossarist::Figure) stores caption/description
    # as language-keyed hashes; the K1 FigureShape constrains them to single
    # xsd:string values, so the transform picks one language at build time.
    class GlossFigure < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :identifier, :string
      attribute :image, :string
      attribute :caption, :string
      attribute :description, :string

      rdf do
        namespace Namespaces::GlossaristNamespace,
                  Namespaces::DctermsNamespace

        subject { |f| "figure/#{f.id}" }

        types "gloss:Figure"

        predicate :image, namespace: Namespaces::GlossaristNamespace,
                          to: :image
        predicate :caption, namespace: Namespaces::GlossaristNamespace,
                            to: :caption
        predicate :description, namespace: Namespaces::DctermsNamespace,
                                to: :description
      end
    end
  end
end
