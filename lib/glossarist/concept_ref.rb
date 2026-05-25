# frozen_string_literal: true

module Glossarist
  class ConceptRef < Lutaml::Model::Serializable
    attribute :source, :string
    attribute :id, :string

    key_value do
      map :source, to: :source
      map :id, to: :id
    end
  end
end
