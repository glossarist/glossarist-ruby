# frozen_string_literal: true

module Glossarist
  # A typed reference to another concept, used inside n-ary relation
  # members and other internal pointer shapes.
  #
  # The base ConceptRef carries `source`, `id`, and `text`. The richer
  # `ConceptReference` (in `glossarist/concept_reference.rb`) extends
  # this with `term`, `urn`, `version`, `ref_type` for use in
  # cross-vocabulary references and relevance contexts.
  #
  # A ConceptRef is identified by `source:id` for external references
  # or just `id` for local references. The `qualified_id` class method
  # is the single SSOT for this string format — used by RelationLoader,
  # the RDF transform, and ConceptRef-bearing data structures.
  class ConceptRef < Lutaml::Model::Serializable
    attribute :source, :string
    attribute :id, :string
    attribute :text, :string

    key_value do
      map :source, to: :source
      map :id, to: :id
      map :text, to: :text
    end

    # SSOT for the canonical "qualified identifier" string of a
    # ConceptRef. Returns:
    #
    #   - "{source}:{id}"         when both source and id are present
    #   - "{id}"                  when only id is present (local ref)
    #   - "{source}:{text}"       when source and text are present (no id)
    #   - "{text}"                when only text is present (external
    #                             concept form, no resolvable id)
    #   - nil                     when the ref is empty / not a ConceptRef
    #
    # Two refs are considered to point at the same concept iff their
    # qualified_id is equal. Tables and registries can use this
    # directly as a hash key.
    def self.qualified_id(ref)
      return nil unless ref.is_a?(ConceptRef)

      id_part = (ref.id.to_s.empty? ? nil : ref.id)
      text_part = (ref.text.to_s.empty? ? nil : ref.text)
      source_part = (ref.source.to_s.empty? ? nil : ref.source)

      if id_part
        source_part ? "#{source_part}:#{id_part}" : id_part
      elsif text_part
        source_part ? "#{source_part}:#{text_part}" : text_part
      end
    end

    # Per-instance convenience delegating to the class method.
    def qualified_id
      self.class.qualified_id(self)
    end

    # True iff +other+ refers to the same concept as self.
    def same_concept?(other)
      qualified_id == self.class.qualified_id(other)
    end
  end
end
