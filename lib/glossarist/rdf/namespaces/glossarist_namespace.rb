# frozen_string_literal: true

module Glossarist
  module Rdf
    module Namespaces
      class GlossaristNamespace < Lutaml::Rdf::Namespace
        uri "https://www.glossarist.org/ontologies/"
        prefix "gloss"
      end
    end
  end
end
