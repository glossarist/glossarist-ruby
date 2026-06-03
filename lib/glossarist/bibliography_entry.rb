# frozen_string_literal: true

module Glossarist
  class BibliographyEntry < Lutaml::Model::Serializable
    attribute :citation_key, :string
    attribute :data, :hash, default: -> { {} }

    key_value do
      map "citation_key", to: :citation_key
      map "data", to: :data
    end
  end
end
