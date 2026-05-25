# frozen_string_literal: true

module Glossarist
  module V3
    class ImageEntry < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :path, :string
      attribute :type, :string, default: -> { "image" }
      attribute :title, :string
      attribute :alt, :string

      key_value do
        map :id, to: :id
        map :path, to: :path
        map :type, to: :type
        map :title, to: :title
        map :alt, to: :alt
      end
    end
  end
end
