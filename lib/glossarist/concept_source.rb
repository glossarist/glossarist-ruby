# frozen_string_literal: true

module Glossarist
  class ConceptSource < Model
    include Glossarist::Utilities::Enum
    include Glossarist::Utilities::CommonFunctions

    register_enum :status, Glossarist::GlossaryDefinition::CONCEPT_SOURCE_STATUSES
    register_enum :type, Glossarist::GlossaryDefinition::CONCEPT_SOURCE_TYPES

    attr_reader :origin
    alias_method :ref, :origin

    attr_accessor :modification

    def initialize(attributes = {})
      if rel = attributes.delete("relationship")
        self.status = rel["type"]
        self.modification = rel["modification"]
      end

      self.origin = slice_keys(attributes, ref_param_names)

      remaining_attributes = attributes.dup
      ref_param_names.each { |k| remaining_attributes.delete(k) }

      super(remaining_attributes)
    end

    def origin=(origin)
      @origin = Citation.new(origin)
    end

    alias_method :ref=, :origin=

    def to_h
      origin_hash = self.origin.to_h.empty? ? nil : self.origin.to_h

      {
        "origin" => origin_hash,
        "type" => type.to_s,
        "status" => status&.to_s,
        "modification" => modification,
      }.compact
    end

    private

    def ref_param_names
      %w[
        ref
        text
        source
        id
        version
        clause
        link
        original
      ]
    end
  end
end
