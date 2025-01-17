# frozen_string_literal: true

module Glossarist
  class RelatedConcept < Lutaml::Model::Serializable
    attribute :content, :string
    attribute :type, :string,
              values: Glossarist::GlossaryDefinition::RELATED_CONCEPT_TYPES
    attribute :ref, Citation

    yaml do
      map :content, to: :content
      map :type, to: :type
      map :ref, with: { from: :ref_from_yaml, to: :ref_to_yaml }
    end

    def ref_to_yaml(model, doc)
      doc["ref"] = Citation.as_yaml(model.ref)["ref"] if model.ref
    end

    def ref_from_yaml(model, value)
      model.ref = Citation.of_yaml(value)
    end
  end
end
