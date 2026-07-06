# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for a dataset-level Formula entity (concept-model v3.1.0 K1).
    #
    # Emits a `gloss:Formula` subject with:
    #   - gloss:expression — xsd:string (one language picked from the localized hash)
    #   - gloss:latexForm — xsd:string (the LaTeX form, when notation is latex)
    #   - dcterms:description — xsd:string (one language picked)
    class GlossFormula < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :identifier, :string
      attribute :expression, :string
      attribute :latex_form, :string
      attribute :description, :string

      rdf do
        namespace Namespaces::GlossaristNamespace,
                  Namespaces::DctermsNamespace

        subject { |f| "formula/#{f.id}" }

        types "gloss:Formula"

        predicate :expression, namespace: Namespaces::GlossaristNamespace,
                               to: :expression
        predicate :latexForm, namespace: Namespaces::GlossaristNamespace,
                              to: :latex_form
        predicate :description, namespace: Namespaces::DctermsNamespace,
                                to: :description
      end
    end
  end
end
