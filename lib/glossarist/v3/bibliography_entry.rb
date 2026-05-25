# frozen_string_literal: true

module Glossarist
  module V3
    class BibliographyEntry < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :reference, :string
      attribute :title, :string
      attribute :link, :string

      key_value do
        map :id, to: :id
        map :reference, to: :reference
        map :title, to: :title
        map :link, to: :link
      end
    end
  end
end
