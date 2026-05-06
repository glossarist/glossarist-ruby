# frozen_string_literal: true

module Glossarist
  module Transforms
    autoload :ConceptToSkosTransform,
             "glossarist/transforms/concept_to_skos_transform"
    autoload :ConceptToTbxTransform,
             "glossarist/transforms/concept_to_tbx_transform"
  end
end
