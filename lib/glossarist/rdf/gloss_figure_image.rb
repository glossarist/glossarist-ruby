# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for one image variant within a Figure (concept-model v3.1.0 K2).
    #
    # Emits a `foaf:Image` subject with:
    #   - dcterms:format — required by K2 ImageShape (e.g. "svg", "png")
    #   - dcterms:language — optional (max 1) — when the variant is localized
    #   - dcat:byteSize — optional (max 1) — when the source model carries it
    #   - gloss:imageRole — the variant's role (vector/raster/dark/light/print)
    #
    # The FigureImage domain model carries src, format, role, width, height,
    # scale. byte_size isn't on the model (it would require file-system
    # inspection); we emit nil when absent, which the RDF layer skips.
    class GlossFigureImage < Lutaml::Model::Serializable
      attribute :src, :string
      attribute :format, :string
      attribute :role, :string
      attribute :byte_size, :integer

      rdf do
        namespace Namespaces::DctermsNamespace,
                  Namespaces::FoafNamespace,
                  Namespaces::DcatNamespace,
                  Namespaces::GlossaristNamespace

        subject { |i| "image/#{i.src}" }

        types "foaf:Image"

        predicate :format, namespace: Namespaces::DctermsNamespace,
                           to: :format
        predicate :byteSize, namespace: Namespaces::DcatNamespace,
                             to: :byte_size
        predicate :imageRole, namespace: Namespaces::GlossaristNamespace,
                              to: :role
      end
    end
  end
end
