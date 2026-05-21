# frozen_string_literal: true

module Glossarist
  # Backward-compatible alias for Reference.
  #
  # Historically, Citation was a separate class for bibliographic references
  # (documents, clauses, pages). It has been unified with ConceptReference
  # into the single Reference class, since both model "an item within a
  # collection" — Citation addresses documents, ConceptReference addresses
  # concepts in termbases.
  Citation = Reference
end
