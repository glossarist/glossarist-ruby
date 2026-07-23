# frozen_string_literal: true

module Glossarist
  module V3
    # PartitiveRelation — an ISO 704 / ISO 1087-1 / ISO 12620
    # partitive relation connecting a comprehensive concept
    # (superordinate concept partitive) to two or more partitive
    # concepts (subordinate concepts partitive) which fitted together
    # constitute the comprehensive.
    #
    # Shown as a rake or bracket in source diagrams. All partitives
    # within one relation are coordinate concepts: they share the
    # comprehensive AND share the criterion of subdivision.
    #
    # Glossarist extensions beyond ISO notation:
    #   - Per-partitive certainty (MemberCertainty)
    #   - plurality.shared_type (the type the partitives share)
    #   - criterion as a structured field (not just diagrammatic)
    #
    # Replaces the prior PartitiveHyperedge class. The "hyperedge"
    # framing was graph-theoretic; ISO calls this a *relation*.
    class PartitiveRelation < Lutaml::Model::Serializable
      DEFAULT_COMPLETENESS = "complete"

      attribute :comprehensive, ConceptRef
      attribute :partitives, PartitiveMember, collection: true
      attribute :completeness, :string,
                values: Glossarist::GlossaryDefinition::COMPLETENESS_VALUES,
                default: -> { DEFAULT_COMPLETENESS }
      attribute :plurality, TypeSharedPlurality
      attribute :criterion, :hash

      key_value do
        map :comprehensive, to: :comprehensive
        map :partitives, to: :partitives
        map :completeness, to: :completeness
        map :plurality, to: :plurality
        map :criterion, to: :criterion
      end

      def validate!
        validate_comprehensive!
        validate_partitives!
        validate_self_loop!
        validate_completeness!
        validate_plurality!
        self
      end

      def complete?
        completeness == "complete"
      end

      def partial?
        completeness == "partial"
      end

      # ISO 704: a partitive relation connects to two or more
      # partitives. A single binary has_part edge is not a
      # PartitiveRelation.
      def coordinate?
        partitives.length >= 2
      end

      private

      def validate_comprehensive!
        return if comprehensive.is_a?(ConceptRef) &&
                  (comprehensive.source || comprehensive.id || comprehensive.text)

        raise ArgumentError,
              "PartitiveRelation#comprehensive must be a non-empty " \
              "ConceptRef (source, id, or text required)"
      end

      def validate_partitives!
        if partitives.empty?
          raise ArgumentError, "PartitiveRelation requires at least one partitive"
        end
        unless coordinate?
          raise ArgumentError,
                "PartitiveRelation requires ≥2 partitives (ISO 704); a single " \
                "binary has_part edge should be used instead"
        end

        partitives.each(&:validate!)
      end

      def validate_self_loop!
        return unless comprehensive.is_a?(ConceptRef)

        comp_key = [comprehensive.source, comprehensive.id]
        partitives.each do |member|
          next unless member.ref.is_a?(ConceptRef)
          next unless [member.ref.source, member.ref.id] == comp_key

          raise ArgumentError,
                "PartitiveRelation#partitives cannot include the comprehensive"
        end
      end

      def validate_completeness!
        return if completeness.nil?

        unless Glossarist::GlossaryDefinition::COMPLETENESS_VALUES
                 .include?(completeness)
          raise ArgumentError,
                "PartitiveRelation#completeness has invalid value " \
                "#{completeness.inspect}; must be one of " \
                "#{GlossaryDefinition::COMPLETENESS_VALUES.join(', ')}"
        end
      end

      def validate_plurality!
        plurality&.validate!
      end
    end
  end
end
