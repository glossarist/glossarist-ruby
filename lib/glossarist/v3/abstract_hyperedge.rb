# frozen_string_literal: true

require "digest"

module Glossarist
  module V3
    # AbstractHyperedge — abstract base shape for all n-ary
    # concept-system relations (PartitiveHyperedge, GenericHyperedge,
    # future AssociativeRelation, SequentialRelation).
    #
    # Carries the shared fields: comprehensive, members[2..*],
    # completeness, criterion, sources, notes, status.
    #
    # Concrete leaves override `members` to specify the typed member
    # class. Shared validations live here.
    class AbstractHyperedge < Lutaml::Model::Serializable
      DEFAULT_COMPLETENESS = "complete"

      attribute :comprehensive, ConceptRef
      attribute :members, HyperedgeMember, collection: true
      attribute :completeness, :string,
                values: Glossarist::GlossaryDefinition::COMPLETENESS_VALUES,
                default: -> { DEFAULT_COMPLETENESS }
      attribute :criterion, :hash
      attribute :sources, ConceptSource, collection: true
      attribute :notes, :hash
      attribute :status, :string,
                values: Glossarist::GlossaryDefinition::CONCEPT_STATUSES

      # Per-file identity — set by RelationLoader on parse, used by
      # HyperedgeWriter on serialize. The wire field is `$id` (JSON
      # Schema convention); the value is `<comp-id>/<criterion-slug>`.
      # Not in key_value because lutaml::Model key_value does not
      # natively express `$`-prefixed keys; handled via custom
      # round-trip in HyperedgeWriter / RelationLoader.
      attr_accessor :file_id

      key_value do
        map :comprehensive, to: :comprehensive
        map :members, to: :members
        map :completeness, to: :completeness
        map :criterion, to: :criterion
        map :sources, to: :sources
        map :notes, to: :notes
        map :status, to: :status
      end

      def initialize(*)
        if instance_of?(AbstractHyperedge)
          raise NotImplementedError,
                "AbstractHyperedge is abstract; instantiate " \
                "PartitiveHyperedge or GenericHyperedge instead"
        end

        super
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

      # Per-file identity derived from comprehensive + criterion.
      # Format: `<comprehensive-id-dir>/<criterion-slug>` where the
      # dir is `<source>-<id>` (downcased, kebab-case) and the slug
      # is the English criterion (kebab-case) or a structural
      # fallback. Stable across runs for the same content.
      #
      # Returns nil if comprehensive is empty.
      def derived_file_id
        return nil unless comprehensive.is_a?(ConceptRef) && comprehensive.id

        comp_dir = comprehensive_dir_name
        return nil unless comp_dir

        slug = criterion_slug
        "#{comp_dir}/#{slug}"
      end

      # File path under `relations/` directory. Uses #derived_file_id
      # unless #file_id was explicitly set (e.g., by RelationLoader
      # preserving the source path on parse).
      def file_path(relations_dir)
        id = file_id || derived_file_id
        return nil unless id

        File.join(relations_dir, "#{id}.yaml")
      end

      # Comprehensive concept as a directory-safe name:
      # `<source>-<id>` lowercased, kebab-case, special chars
      # (including dots) replaced with dashes. Matches the concept-model
      # fixtures (vim-112-02-09, oiml-5-1, example-116-01-01).
      def comprehensive_dir_name
        return nil unless comprehensive.is_a?(ConceptRef)

        parts = [comprehensive.source, comprehensive.id].compact.reject(&:empty?)
        return nil if parts.empty?

        parts.join("-").downcase.gsub(/[^a-z0-9\-]/, "-")
             .gsub(/-{2,}/, "-").gsub(/\A-|-\z/, "")
      end

      # Kebab-case slug derived from the English criterion. Falls back
      # to "decomposition-N" when no English criterion exists (N is
      # derived from the criterion hash for stability).
      def criterion_slug
        eng = criterion.is_a?(Hash) ? (criterion["eng"] || criterion[:eng]) : nil
        return "decomposition-#{criterion_hash}" if eng.nil? || eng.to_s.empty?

        eng.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
      end

      private

      def criterion_hash
        return "0" unless criterion.is_a?(Hash) && !criterion.empty?

        Digest::MD5.hexdigest(criterion.sort.to_h.inspect)[0..5]
      end

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
          next unless comp_key == [member.ref.source, member.ref.id]

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
