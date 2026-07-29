# frozen_string_literal: true

module Glossarist
  module V3
    # ConceptSystemMember — abstract base shape for members of any
    # n-ary concept-system relation (PartitiveMember, GenericMember,
    # future AssociativeMember, SequentialMember).
    #
    # Carries the shared ISO 704:2022 MECE dimensions: presence × count,
    # plus the orthogonal is_delimiting flag.
    #
    # Concrete leaf classes inherit and may add type-specific fields.
    # See docs/design/abstract-nary-relation.md (concept-model repo).
    class ConceptSystemMember < Lutaml::Model::Serializable
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

      private

      def validate_ref!
        return if ref.is_a?(ConceptRef) && (ref.source || ref.id || ref.text)

        raise ArgumentError,
              "#{self.class.name}#ref must be a non-empty ConceptRef " \
              "(source, id, or text required)"
      end

      def validate_presence_count!
        unless Glossarist::GlossaryDefinition::PARTITIVE_PRESENCE_VALUES
                 .include?(presence)
          raise ArgumentError,
                "#{self.class.name}#presence has invalid value " \
                "#{presence.inspect}; must be one of " \
                "#{GlossaryDefinition::PARTITIVE_PRESENCE_VALUES.join(', ')}"
        end

        unless Glossarist::GlossaryDefinition::PARTITIVE_COUNT_VALUES
                 .include?(count)
          raise ArgumentError,
                "#{self.class.name}#count has invalid value " \
                "#{count.inspect}; must be one of " \
                "#{GlossaryDefinition::PARTITIVE_COUNT_VALUES.join(', ')}"
        end

        if presence == "optional" && count == "at_least_one"
          raise ArgumentError,
                "#{self.class.name} presence=optional + count=at_least_one is " \
                "invalid — it collapses to optional + multiple (zero or more). " \
                "Use presence: optional, count: multiple instead."
        end
      end
    end
  end
end
