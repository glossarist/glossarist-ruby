# frozen_string_literal: true

module Glossarist
  # A non-verbal representation used to help define a concept, following
  # ISO 10241-1 §6.5.
  #
  # Non-verbal representations are associated resources (images, tables,
  # formulas) that live outside the concept model. They are referenced by URI
  # and can be shared across concepts. The resource belongs either to the
  # dataset package (relative path) or is externally referenced (URL/URN).
  #
  # Each non-verbal representation specifies:
  # - +type+: one of "image", "table", "formula"
  # - +ref+: URI reference to the resource (relative path, URN, or URL)
  # - +text+: optional text description or alt text
  # - +sources+: bibliographic sources for the representation
  class NonVerbRep < Lutaml::Model::Serializable
    attribute :type, :string
    attribute :ref, :string
    attribute :text, :string
    attribute :sources, ConceptSource, collection: true

    key_value do
      map :type, to: :type
      map :ref, to: :ref
      map :text, to: :text
      map :sources, to: :sources
    end
  end
end
