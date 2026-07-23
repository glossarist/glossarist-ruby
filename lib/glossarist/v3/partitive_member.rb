# frozen_string_literal: true

module Glossarist
  module V3
    # PartitiveMember — one member of a PartitiveRelation, carrying
    # a ConceptRef to the partitive concept plus optional certainty
    # metadata (Glossarist extension beyond ISO 704 notation).
    #
    # A PartitiveMember with no certainty field is implicitly
    # confirmed.
    class PartitiveMember < Lutaml::Model::Serializable
      DEFAULT_CERTAINTY = "confirmed"

      attribute :ref, ConceptRef
      attribute :certainty, :string,
                values: Glossarist::GlossaryDefinition::MEMBER_CERTAINTY_VALUES,
                default: -> { DEFAULT_CERTAINTY }

      key_value do
        map :ref, to: :ref
        map :certainty, to: :certainty
      end

      def validate!
        validate_ref!
        validate_certainty!
        self
      end

      def confirmed?
        certainty == DEFAULT_CERTAINTY
      end

      def possible?
        certainty == "possible"
      end

      private

      def validate_ref!
        return if ref.is_a?(ConceptRef) && (ref.source || ref.id || ref.text)

        raise ArgumentError,
              "PartitiveMember#ref must be a non-empty ConceptRef " \
              "(source, id, or text required)"
      end

      def validate_certainty!
        return if certainty.nil?

        unless Glossarist::GlossaryDefinition::MEMBER_CERTAINTY_VALUES
                 .include?(certainty)
          raise ArgumentError,
                "PartitiveMember#certainty has invalid value " \
                "#{certainty.inspect}; must be one of " \
                "#{GlossaryDefinition::MEMBER_CERTAINTY_VALUES.join(', ')}"
        end
      end
    end
  end
end
