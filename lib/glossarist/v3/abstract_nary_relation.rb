# frozen_string_literal: true

module Glossarist
  module V3
    # AbstractNaryRelation — abstract base shape for all n-ary
    # concept-system relations (PartitiveRelation, GenericRelation,
    # future AssociativeRelation, SequentialRelation).
    #
    # Carries the shared fields: comprehensive, members[2..*],
    # completeness, criterion, sources, notes, status.
    #
    # Concrete leaves override `members` to specify the typed member
    # class. Shared validations live here.
    class AbstractNaryRelation < Lutaml::Model::Serializable
      DEFAULT_COMPLETENESS = "complete"

      attribute :comprehensive, ConceptRef
      attribute :members, ConceptSystemMember, collection: true
      attribute :completeness, :string,
                values: Glossarist::GlossaryDefinition::COMPLETENESS_VALUES,
                default: -> { DEFAULT_COMPLETENESS }
      attribute :criterion, :hash
      attribute :sources, ConceptSource, collection: true
      attribute :notes, :hash
      attribute :status, :string,
                values: Glossarist::GlossaryDefinition::CONCEPT_STATUSES

      key_value do
        map :comprehensive, to: :comprehensive
        map :members, to: :members
        map :completeness, to: :completeness
        map :criterion, to: :criterion
        map :sources, to: :sources
        map :notes, to: :notes
        map :status, to: :status
      end

      def validate!
        validate_comprehensive!
        validate_members!
        validate_self_loop!
        validate_completeness!
        self
      end

      def complete?
        completeness == "complete"
      end

      def partial?
        completeness == "partial"
      end

      # ISO 704: a rake connects to two or more members. A single
      # binary edge is not an n-ary relation.
      def coordinate?
        members.length >= 2
      end

      private

      def validate_comprehensive!
        return if comprehensive.is_a?(ConceptRef) &&
                  (comprehensive.source || comprehensive.id || comprehensive.text)

        raise ArgumentError,
              "#{self.class.name}#comprehensive must be a non-empty " \
              "ConceptRef (source, id, or text required)"
      end

      def validate_members!
        if members.empty?
          raise ArgumentError, "#{self.class.name} requires at least one member"
        end
        unless coordinate?
          raise ArgumentError,
                "#{self.class.name} requires >=2 members (ISO 704); a single " \
                "binary edge should be used instead"
        end

        members.each(&:validate!)
      end

      def validate_self_loop!
        return unless comprehensive.is_a?(ConceptRef)

        comp_key = [comprehensive.source, comprehensive.id]
        members.each do |member|
          next unless member.ref.is_a?(ConceptRef)
          next unless [member.ref.source, member.ref.id] == comp_key

          raise ArgumentError,
                "#{self.class.name}#members cannot include the comprehensive"
        end
      end

      def validate_completeness!
        return if completeness.nil?

        unless Glossarist::GlossaryDefinition::COMPLETENESS_VALUES
                 .include?(completeness)
          raise ArgumentError,
                "#{self.class.name}#completeness has invalid value " \
                "#{completeness.inspect}; must be one of " \
                "#{GlossaryDefinition::COMPLETENESS_VALUES.join(', ')}"
        end
      end
    end
  end
end
