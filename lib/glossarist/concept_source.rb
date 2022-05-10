# frozen_string_literal: true

module Glossarist
  class ConceptSource < Model
    include Glossarist::Utilities::Enum

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

      self.origin = attributes.slice(*ref_param_names)

      remaining_attributes = attributes.dup
      ref_param_names.each { |k| remaining_attributes.delete(k) }

      super(remaining_attributes)
    end

    def origin=(origin)
      @origin = Ref.new(origin)
    end

    alias_method :ref=, :origin=

    def to_h
      {
        "type" => type.to_s,
        "status" => status.to_s,
        "origin" => origin.to_h,
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
