# frozen_string_literal: true

module Glossarist
  # A reference to a bibliographic entry (an external document), distinct from
  # a ConceptReference (a cross-reference to another concept in the same or
  # another registry).
  #
  # BibliographicReference and ConceptReference share some method names
  # (`cite?`, `local?`, `external?`) so that validation rules and reference
  # extractors can call a uniform protocol on mixed collections without
  # type-checking. BibliographicReference always returns false for these —
  # it is never an inline `{{cite:id}}` mention, never a local concept link,
  # never an external concept link. It is its own kind of reference.
  class BibliographicReference
    attr_reader :anchor, :location

    def initialize(anchor:, location: nil)
      @anchor = anchor
      @location = location
    end

    def dedup_key
      anchor
    end

    def cite?
      false
    end

    def local?
      false
    end

    def external?
      false
    end
  end
end
