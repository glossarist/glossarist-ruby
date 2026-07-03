# frozen_string_literal: true

module Glossarist
  # A reference to a bibliographic entry (an external document), distinct from
  # a ConceptReference (a cross-reference to another concept in the same or
  # another registry).
  #
  # BibliographicReference is produced by ReferenceExtractor from AsciiDoc
  # <<anchor>> xrefs and from model-level source citations. It participates
  # in the {Reference} protocol so validation rules iterating mixed reference
  # collections can call `cite?` / `local?` / `external?` without
  # type-checking. All three predicates default to false (a bibliographic
  # reference is never an inline `{{cite:id}}` mention, never a concept
  # cross-ref).
  class BibliographicReference
    include Reference

    attr_reader :anchor, :location

    def initialize(anchor:, location: nil)
      @anchor = anchor
      @location = location
    end

    def dedup_key
      anchor
    end
  end
end
