# frozen_string_literal: true

module Glossarist
  module V3
    # PartitiveMember — one member of a PartitiveRelation, carrying
    # a ConceptRef to the partitive concept plus ISO 704:2022
    # multiplicity and delimiting metadata.
    #
    # ISO 704:2022 partitive member notation uses two orthogonal
    # dimensions (MECE decomposition):
    #
    #   presence (line style — solid vs dashed):
    #     required   — solid line (must exist in every instance)
    #     optional   — dashed line (may exist; exists in some instances)
    #
    #   count (line count — how many):
    #     exactly_one  — 1 line
    #     at_least_one — 1 solid + 1 dashed
    #     multiple     — 2 lines
    #
    # Valid combinations (5):
    #   required + exactly_one    = compulsory (1 solid)
    #   optional + exactly_one    = optional (1 dashed)
    #   required + multiple       = compulsory_multiple (2 solid)
    #   optional + multiple       = optional_multiple (2 dashed)
    #   required + at_least_one   = compulsory_at_least_one (1 solid + 1 dashed)
    #
    # Invalid: optional + at_least_one (collapses to optional + multiple
    # because "at least one, if present" = "zero or more" = optional_multiple).
    #
    # is_delimiting (orthogonal, bold 3x-width line in diagram):
    #   A delimiting part behaves like a delimiting characteristic:
    #   it distinguishes the comprehensive from coordinate concepts.
    #   Example (ISO 704 §5.5.4.2.2): for "optomechanical mouse",
    #   the delimiting parts are mouse ball, x/y-axis rollers,
    #   infrared emitter/sensor — they distinguish it from
    #   "mechanical mouse" and "optical mouse". Mouse button is
    #   NOT delimiting (all computer mice have buttons).
    class PartitiveMember < Lutaml::Model::Serializable
      DEFAULT_PRESENCE = "required"
      DEFAULT_COUNT = "exactly_one"

      attribute :ref, ConceptRef
      attribute :presence, :string,
                values: Glossarist::GlossaryDefinition::PARTITIVE_PRESENCE_VALUES,
                default: -> { DEFAULT_PRESENCE }
      attribute :count, :string,
                values: Glossarist::GlossaryDefinition::PARTITIVE_COUNT_VALUES,
                default: -> { DEFAULT_COUNT }
      attribute :is_delimiting, :boolean, default: -> { false }

      key_value do
        map :ref, to: :ref
        map :presence, to: :presence
        map :count, to: :count
        map :is_delimiting, to: :is_delimiting
      end

      def validate!
        validate_ref!
        validate_presence_count!
        self
      end

      def required?
        presence == "required"
      end

      def optional?
        presence == "optional"
      end

      def delimiting?
        is_delimiting == true
      end

      # Derived ISO 704 name for display. Returns the flat-enum
      # name that corresponds to this (presence, count) pair.
      def iso704_name
        case [presence, count]
        when ["required", "exactly_one"] then "compulsory"
        when ["optional", "exactly_one"] then "optional"
        when ["required", "multiple"] then "compulsory_multiple"
        when ["optional", "multiple"] then "optional_multiple"
        when ["required", "at_least_one"] then "compulsory_at_least_one"
        else raise ArgumentError,
                     "invalid combination presence=#{presence} count=#{count}"
        end
      end

      private

      def validate_ref!
        return if ref.is_a?(ConceptRef) && (ref.source || ref.id || ref.text)

        raise ArgumentError,
              "PartitiveMember#ref must be a non-empty ConceptRef " \
              "(source, id, or text required)"
      end

      def validate_presence_count!
        unless Glossarist::GlossaryDefinition::PARTITIVE_PRESENCE_VALUES
                 .include?(presence)
          raise ArgumentError,
                "PartitiveMember#presence has invalid value " \
                "#{presence.inspect}; must be one of " \
                "#{GlossaryDefinition::PARTITIVE_PRESENCE_VALUES.join(', ')}"
        end

        unless Glossarist::GlossaryDefinition::PARTITIVE_COUNT_VALUES
                 .include?(count)
          raise ArgumentError,
                "PartitiveMember#count has invalid value " \
                "#{count.inspect}; must be one of " \
                "#{GlossaryDefinition::PARTITIVE_COUNT_VALUES.join(', ')}"
        end

        if presence == "optional" && count == "at_least_one"
          raise ArgumentError,
                "PartitiveMember presence=optional + count=at_least_one is " \
                "invalid — it collapses to optional + multiple (zero or more). " \
                "Use presence: optional, count: multiple instead."
        end
      end
    end
  end
end
