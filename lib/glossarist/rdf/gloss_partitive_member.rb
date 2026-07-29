# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for V3::PartitiveMember. Inherits attributes and
    # deterministic_id from GlossNaryMember. The `rdf do` block
    # re-declares the predicates because lutaml-model's `rdf` DSL
    # replaces the parent mapping (not extends).
    class GlossPartitiveMember < GlossNaryMember
      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |m| "partitiveMember/#{GlossPartitiveMember.deterministic_id(m)}" }

        types "gloss:PartitiveMember"

        predicate :refSource, namespace: Namespaces::GlossaristNamespace,
                              to: :ref_source
        predicate :refId, namespace: Namespaces::GlossaristNamespace,
                          to: :ref_id
        predicate :refText, namespace: Namespaces::GlossaristNamespace,
                            to: :ref_text
        predicate :presence, namespace: Namespaces::GlossaristNamespace,
                             to: :presence
        predicate :count, namespace: Namespaces::GlossaristNamespace,
                          to: :count
        predicate :isDelimiting, namespace: Namespaces::GlossaristNamespace,
                                 to: :is_delimiting
      end
    end
  end
end
