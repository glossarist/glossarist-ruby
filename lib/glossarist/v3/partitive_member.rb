# frozen_string_literal: true

module Glossarist
  module V3
    # PartitiveMember — one member of a PartitiveRelation, carrying
    # a ConceptRef to the partitive concept plus ISO 704:2022
    # multiplicity and delimiting metadata.
    #
    # ISO 704:2022 partitive member notation:
    #
    #   multiplicity (diagram line notation):
    #     compulsory          — 1 solid line (must exist in every instance)
    #     optional            — 1 dashed line (exists in some instances only)
    #     compulsory_multiple — 2 solid lines (multiple must exist)
    #     optional_multiple   — 2 dashed lines (multiple may exist)
    #     at_least_one        — 1 solid + 1 dashed line (≥1 must exist)
    #
    #   is_delimiting (orthogonal, bold 3x-width line in diagram):
    #     A delimiting part behaves like a delimiting characteristic:
    #     it distinguishes the comprehensive from coordinate concepts.
    #     Example (ISO 704 §5.5.4.2.2): for "optomechanical mouse",
    #     the delimiting parts are mouse ball, x/y-axis rollers,
    #     infrared emitter/sensor — they distinguish it from
    #     "mechanical mouse" and "optical mouse". Mouse button is
    #     NOT delimiting (all computer mice have buttons).
    class PartitiveMember < Lutaml::Model::Serializable
      DEFAULT_MULTIPLICITY = "compulsory"

      attribute :ref, ConceptRef
      attribute :multiplicity, :string,
                values: Glossarist::GlossaryDefinition::MULTIPLICITY_VALUES,
                default: -> { DEFAULT_MULTIPLICITY }
      attribute :is_delimiting, :boolean, default: -> { false }

      key_value do
        map :ref, to: :ref
        map :multiplicity, to: :multiplicity
        map :is_delimiting, to: :is_delimiting
      end

      def validate!
        validate_ref!
        validate_multiplicity!
        self
      end

      def compulsory?
        multiplicity == "compulsory"
      end

      def optional?
        multiplicity == "optional"
      end

      def delimiting?
        is_delimiting == true
      end

      private

      def validate_ref!
        return if ref.is_a?(ConceptRef) && (ref.source || ref.id || ref.text)

        raise ArgumentError,
              "PartitiveMember#ref must be a non-empty ConceptRef " \
              "(source, id, or text required)"
      end

      def validate_multiplicity!
        return if multiplicity.nil?

        unless Glossarist::GlossaryDefinition::MULTIPLICITY_VALUES
                 .include?(multiplicity)
          raise ArgumentError,
                "PartitiveMember#multiplicity has invalid value " \
                "#{multiplicity.inspect}; must be one of " \
                "#{GlossaryDefinition::MULTIPLICITY_VALUES.join(', ')}"
        end
      end
    end
  end
end
