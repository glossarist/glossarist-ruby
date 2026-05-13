# frozen_string_literal: true

module Glossarist
  # A typed reference to another concept, either local (within the same
  # glossary) or external (in another concept registry).
  #
  # Local references use +concept_id+ without +source+. External references
  # use +source+ (a registry URN prefix) and +concept_id+ to identify the
  # target concept, or a direct +urn+ field for formal URN references.
  class ConceptReference < Lutaml::Model::Serializable
    attribute :term, :string
    attribute :concept_id, :string
    attribute :source, :string
    attribute :ref_type, :string
    attribute :urn, :string

    key_value do
      map :term, to: :term
      map :concept_id, to: :concept_id
      map :source, to: :source
      map :ref_type, to: :ref_type
      map :urn, to: :urn
    end

    def local?
      %w[local designation].include?(ref_type) ||
        (ref_type.nil? && (source.nil? || source.empty?))
    end

    def external?
      !local?
    end

    def dedup_key
      concept_id ? [source, concept_id] : [source, concept_id, term]
    end
  end
end
