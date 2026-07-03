# frozen_string_literal: true

module Glossarist
  # Shared protocol for all reference kinds produced by ReferenceExtractor.
  #
  # ConceptReference, BibliographicReference, AssetReference, and the
  # NonVerbalReference family (Figure/Table/Formula) all participate in
  # validation rules that iterate a mixed collection extracted from a
  # concept's text fields. Rules such as CiteRefIntegrityRule call
  # `select(&:cite?)` on these mixed collections and must not crash on
  # any member.
  #
  # The defaults here represent the common case: most reference kinds are
  # neither inline `{{cite:...}}` mentions, nor local/external concept
  # cross-refs. ConceptReference overrides all three predicates because
  # its semantics depend on ref_type and source.
  #
  # Including this module in a new reference class is sufficient to make
  # it participate correctly in mixed-collection validation rules.
  module Reference
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
