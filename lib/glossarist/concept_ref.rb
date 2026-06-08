# frozen_string_literal: true

module Glossarist
  class ConceptRef < Lutaml::Model::Serializable
    attribute :source, :string
    attribute :id, :string
    attribute :text, :string

    key_value do
      map :source, to: :source
      map :id, to: :id
      map :text, to: :text
    end
  end
end
