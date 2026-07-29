# frozen_string_literal: true

module Glossarist
  module V3
    # HyperedgeMember — abstract base shape for members of any
    # n-ary concept-system relation (PartitiveMember, GenericMember,
    # future AssociativeMember, SequentialMember).
    #
    # Carries the shared ISO 704:2022 MECE dimensions: presence × count,
    # plus the orthogonal is_delimiting flag.
    #
    # Concrete leaf classes inherit and may add type-specific fields.
    # See docs/design/abstract-nary-relation.md (concept-model repo).
    class HyperedgeMember < Lutaml::Model::Serializable
      DEFAULT_PRESENCE = "required"
      DEFAULT_COUNT = "exactly_one"

      attribute :ref, ConceptRef
      attribute :presence, :string,
                values: Glossarist::GlossaryDefinition::MEMBER_PRESENCE_VALUES,
                default: -> { DEFAULT_PRESENCE }
      attribute :count, :string,
                values: Glossarist::GlossaryDefinition::MEMBER_COUNT_VALUES,
                default: -> { DEFAULT_COUNT }
      attribute :is_delimiting, :boolean, default: -> { false }

      key_value do
        map :ref, to: :ref
        map :presence, to: :presence
        map :count, to: :count
        map :is_delimiting, to: :is_delimiting
      end

      def initialize(*)
        if instance_of?(HyperedgeMember)
          raise NotImplementedError,
                "HyperedgeMember is abstract; instantiate " \
                "PartitiveMember or GenericMember instead"
        end

        super
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

      # Delegates the MECE combination check to Multiplicity (the SSOT).
      # Multiplicity.multiplicity_from_pair raises ArgumentError on the
      # invalid (optional + at_least_one) combo with the canonical message.
      # The returned name is discarded — only the validation side matters.
      def validate_presence_count!
        unless Glossarist::GlossaryDefinition::MEMBER_PRESENCE_VALUES
            .include?(presence)
          raise ArgumentError,
                "#{self.class.name}#presence has invalid value " \
                "#{presence.inspect}; must be one of " \
                "#{GlossaryDefinition::MEMBER_PRESENCE_VALUES.join(', ')}"
        end

        unless Glossarist::GlossaryDefinition::MEMBER_COUNT_VALUES
            .include?(count)
          raise ArgumentError,
                "#{self.class.name}#count has invalid value " \
                "#{count.inspect}; must be one of " \
                "#{GlossaryDefinition::MEMBER_COUNT_VALUES.join(', ')}"
        end

        Multiplicity.multiplicity_from_pair(presence, count)
      end
    end
  end
end
