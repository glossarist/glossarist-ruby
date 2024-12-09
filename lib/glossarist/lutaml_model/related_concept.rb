# frozen_string_literal: true

module Glossarist
  module LutamlModel
    class RelatedConcept < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :type, :string, values: Glossarist::GlossaryDefinition::RELATED_CONCEPT_TYPES
      attribute :ref, Citation

      yaml do
        map :content, to: :content
        map :type, to: :type
        map :ref, to: :ref
      end

      # def ref_to_yaml(model, doc)
      #   binding.irb
      #   doc
      # end
    
      # def ref_from_yaml(model, value)
      #   model.ref = value
      # end
    end
  end
end
