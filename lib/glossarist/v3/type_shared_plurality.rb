# frozen_string_literal: true

module Glossarist
  module V3
    # TypeSharedPlurality — semantic claims encoded by ISO 704's
    # close-set double line and broken line notation, promoted from
    # diagram-notation flags to structured data so tools can reason
    # about plurality directly.
    #
    # A PartitiveRelation has at most one TypeSharedPlurality block.
    # Absent means: no type-shared plurality claim is being made.
    #
    # Replaces the prior `markers` field (which encoded the same
    # information as opaque strings like "double" and "dashed").
    class TypeSharedPlurality < Lutaml::Model::Serializable
      attribute :is_shared, :boolean
      attribute :is_uncertain, :boolean, default: -> { false }
      attribute :shared_type, ConceptRef

      key_value do
        map :is_shared, to: :is_shared
        map :is_uncertain, to: :is_uncertain
        map :shared_type, to: :shared_type
      end

      def validate!
        unless is_shared.is_a?(TrueClass) || is_shared.is_a?(FalseClass)
          raise ArgumentError,
                "TypeSharedPlurality#is_shared is required (boolean)"
        end

        if is_uncertain == true && is_shared == false
          raise ArgumentError,
                "TypeSharedPlurality#is_uncertain requires is_shared: true " \
                "(ISO 704 broken line qualifies the close-set double line claim)"
        end

        self
      end
    end
  end
end
