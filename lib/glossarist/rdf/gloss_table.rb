# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for a dataset-level Table entity (concept-model v3.1.0 K1).
    #
    # Emits a `gloss:Table` subject with:
    #   - gloss:content — xsd:string (serialized table content)
    #   - gloss:caption — xsd:string (one language picked)
    #   - dcterms:title — xsd:string (the table identifier, used as title)
    class GlossTable < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :identifier, :string
      attribute :content, :string
      attribute :caption, :string

      rdf do
        namespace Namespaces::GlossaristNamespace,
                  Namespaces::DctermsNamespace

        subject { |t| "table/#{t.id}" }

        types "gloss:Table"

        predicate :content, namespace: Namespaces::GlossaristNamespace,
                            to: :content
        predicate :caption, namespace: Namespaces::GlossaristNamespace,
                            to: :caption
        predicate :title, namespace: Namespaces::DctermsNamespace,
                          to: :identifier
      end
    end
  end
end
