# frozen_string_literal: true

module Glossarist
  class ConceptDiff < Lutaml::Model::Serializable
    attribute :concept_id, :string
    attribute :similarity, :float
    attribute :diff_tree, :string

    key_value do
      map :concept_id, to: :concept_id
      map :similarity, to: :similarity
      map :diff_tree, to: :diff_tree
    end
  end
end
