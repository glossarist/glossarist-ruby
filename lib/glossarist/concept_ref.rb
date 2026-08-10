# frozen_string_literal: true

module Glossarist
  # A typed reference to another concept, used inside n-ary relation
  # members and other internal pointer shapes.
  #
  # The base ConceptRef carries `source`, `id`, `text`, `external`, and
  # `ellipsis`. The richer `ConceptReference` (in
  # `glossarist/concept_reference.rb`) extends this with `term`, `urn`,
  # `version`, `ref_type` for use in cross-vocabulary references and
  # relevance contexts.
  #
  # A ConceptRef is identified by `source:id` for external references
  # or just `id` for local references. The `qualified_id` class method
  # is the single SSOT for this string format — used by RelationLoader,
  # the RDF transform, and ConceptRef-bearing data structures.
  #
  # == External concepts (parenthetical notation)
  #
  # ISO 704:2022 uses parenthetical notation for external concepts —
  # concepts referenced from this dataset but defined elsewhere. The
  # `external: true` flag marks such a ref. External refs carry `text`
  # (the parenthetical label) but NOT `source`/`id`.
  #
  # == Ellipsis (structural marker)
  #
  # An ellipsis ref marks "further members exist but are not encoded."
  # It is NOT a concept — it's a structural marker on the hyperedge.
  # An ellipsis ref carries NO other fields (no source, id, text).
  class ConceptRef < Lutaml::Model::Serializable
    attribute :source, :string
    attribute :id, :string
    attribute :text, :string
    attribute :external, :boolean, default: -> { false }
    attribute :ellipsis, :boolean, default: -> { false }

    key_value do
      map :source, to: :source
      map :id, to: :id
      map :text, to: :text
      map :external, to: :external
      map :ellipsis, to: :ellipsis
    end

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

    def qualified_id
      self.class.qualified_id(self)
    end

    def same_concept?(other)
      qualified_id == self.class.qualified_id(other)
    end

    def resolved?
      !source.to_s.empty? && !id.to_s.empty?
    end

    def external?
      external == true
    end

    def ellipsis?
      ellipsis == true
    end

    def text_only?
      !text.to_s.empty? && !resolved? && !external?
    end

    def validate_ref!
      if ellipsis? && (source || id || text || external?)
        raise ArgumentError,
              "ConceptRef with ellipsis: true must not carry any " \
              "other field (source, id, text, external)"
      end

      if external? && (source || id)
        raise ArgumentError,
              "ConceptRef with external: true must not carry " \
              "source/id — use text for the parenthetical label"
      end

      if !source && !id && !text && !external? && !ellipsis?
        raise ArgumentError,
              "ConceptRef must have at least one of: source+id, text, " \
              "external, or ellipsis"
      end

      self
    end
  end
end
