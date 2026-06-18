# frozen_string_literal: true

module Glossarist
  # A single bibliographic item in a dataset's bibliography.
  #
  # A bibliography is an ordered collection of references, so bibliography.yaml
  # is a YAML sequence (array) of these typed entries. The entry's identifier is
  # the +id+ field on each item — never an out-of-band hash key.
  class BibliographyEntry < Lutaml::Model::Serializable
    attribute :id, :string
    attribute :reference, :string
    attribute :title, :string
    attribute :link, :string
    attribute :type, :string

    key_value do
      map :id, to: :id
      map :reference, to: :reference
      map :title, to: :title
      map :link, to: :link
      map :type, to: :type
    end
  end
end
