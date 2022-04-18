# frozen_string_literal: true

module Glossarist
  class RelatedConcept < Model
    include Glossarist::Utilities::Enum

    register_enum :type, Glossarist::GlossaryDefinition::RELATED_CONCEPT_TYPES

    # @return [String]
    attr_accessor :content

    # Reference to the related concept.
    # @return [Ref]
    attr_reader :ref

    def ref=(ref)
      @ref = Ref.new(ref)
    end

    def to_h
      reference = ref&.to_h
      reference&.merge!(reference&.delete("ref"))

      {
        "type" => type.to_s,
        "content" => content,
        "ref" => reference,
      }.compact
    end
  end
end
