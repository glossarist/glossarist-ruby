# frozen_string_literal: true

require "lutaml/turtle"

# Bridge between lutaml-model's Transform hook and Serializable instances.
#
# lutaml-model defines `additional_resource_triples(instance, subject_uri,
# mapping)` on Lutaml::Turtle::Transform and calls it from `build_graph`.
# The Transform is a separate object from the model instance, so the model
# cannot directly emit extra RDF statements.
#
# Models that want to emit extra RDF (e.g., direct SKOS alongside reified
# SKOS-XL) include `EmitsExtraTriples` and override `emit_extra_triples`.
module Glossarist
  module Rdf
    module EmitsExtraTriples
      def emit_extra_triples(_subject_uri, _mapping)
        []
      end
    end

    module LutamlTurtleTransformExt
      def additional_resource_triples(instance, subject_uri, mapping)
        triples = super
        return triples unless instance.is_a?(EmitsExtraTriples)

        triples + Array(instance.emit_extra_triples(subject_uri, mapping))
      end
    end
  end
end

Lutaml::Turtle::Transform.prepend(Glossarist::Rdf::LutamlTurtleTransformExt)
