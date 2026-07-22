# frozen_string_literal: true

module Glossarist
  module V3
    # PartitiveHyperedge — a one-to-many partitive decomposition.
    #
    # One comprehensive concept (the whole) is related to one or more
    # parts as a SINGLE relationship. Captures invariants that binary
    # RelatedConcept edges cannot:
    #
    #   - which comprehensive owns which parts (set membership)
    #   - plurality markers from the source diagram (double / dashed)
    #   - enumeration completeness (closed: all parts listed; open:
    #     other parts may exist)
    #
    # Enum values are SSOT-loaded from `config.yml` via
    # `GlossaryDefinition`. The `values:` option on each attribute
    # documents the enum for schema generation. lutaml-model 0.8.x
    # does NOT enforce `values:` on assignment — semantic checks live
    # in `Validation::Rules::PartitiveHyperedgeRule` (auto-registered
    # via `Validation::Rules`). The model's `validate!` method covers
    # type-shape invariants that fail loudly at construction (empty
    # comprehensive, empty parts, self-loop, invalid enum values).
    #
    # Note on duplicates: lutaml-model's enum-collection setter
    # dedupes silently via the getter, so duplicate markers at
    # construction time are silently coerced to a unique set. We do
    # not attempt to override this; the framework's Set semantics are
    # the data contract.
    #
    # `content` is a localized string hash `{ "eng" => "...", "fra" => "..." }`
    # keyed by ISO 639 language code. All free-form text fields in
    # Glossarist MUST be localized — the project is multi-language by
    # domain. Read values via the `LocalizedString` helper module:
    #
    #   Glossarist::LocalizedString.fetch(he.content, "eng")
    #
    # Matches the pattern used by `Section#names`, `DatasetRegister#description`,
    # `Formula#expression`, `Table#content`. The concept-model schema and
    # `RelatedConcept#content` still declare `type: string` today — those
    # are bugs to fix, not patterns to copy.
    class PartitiveHyperedge < Lutaml::Model::Serializable
      DEFAULT_ENUMERATION = "closed"

      attribute :comprehensive, ConceptRef
      attribute :parts, ConceptRef, collection: true
      attribute :enumeration, :string,
                values: Glossarist::GlossaryDefinition::PARTITIVE_ENUMERATION_VALUES,
                default: -> { DEFAULT_ENUMERATION }
      attribute :markers, :string,
                values: Glossarist::GlossaryDefinition::PLURALITY_MARKER_VALUES,
                collection: true
      attribute :content, :hash

      key_value do
        map :comprehensive, to: :comprehensive
        map :parts, to: :parts
        map :enumeration, to: :enumeration
        map :markers, to: :markers
        map :content, to: :content
      end

      # Type-shape validators — invoke via `validate!` after
      # construction. We do NOT call these from `initialize` because
      # lutaml-model deserializes attributes AFTER `new` returns (see
      # `Lutaml::KeyValue::Transform#data_to_model`); validating in
      # `initialize` sees a half-built instance and raises spuriously.

      def validate!
        validate_comprehensive!
        validate_parts!
        validate_self_loop!
        validate_markers!
        validate_enumeration!
        self
      end

      private

      def validate_comprehensive!
        return if comprehensive.is_a?(ConceptRef) &&
                  (comprehensive.source || comprehensive.id)

        raise ArgumentError,
              "PartitiveHyperedge#comprehensive must be a non-empty " \
              "ConceptRef (source or id required)"
      end

      def validate_parts!
        return if Array(parts).any?

        raise ArgumentError, "PartitiveHyperedge requires at least one part"
      end

      def validate_self_loop!
        return unless comprehensive.is_a?(ConceptRef)

        comp_key = [comprehensive.source, comprehensive.id]
        parts.each do |p|
          next unless p.is_a?(ConceptRef)
          next unless [p.source, p.id] == comp_key

          raise ArgumentError,
                "PartitiveHyperedge#parts cannot include the comprehensive"
        end
      end

      def validate_markers!
        Array(markers).each do |m|
          unless Glossarist::GlossaryDefinition::PLURALITY_MARKER_VALUES.include?(m)
            raise ArgumentError,
                  "PartitiveHyperedge#markers contains invalid value #{m.inspect}; " \
                  "must be one of " \
                  "#{GlossaryDefinition::PLURALITY_MARKER_VALUES.join(', ')}"
          end
        end
      end

      def validate_enumeration!
        return if enumeration.nil?

        unless Glossarist::GlossaryDefinition::PARTITIVE_ENUMERATION_VALUES
                 .include?(enumeration)
          raise ArgumentError,
                "PartitiveHyperedge#enumeration has invalid value " \
                "#{enumeration.inspect}; must be one of " \
                "#{GlossaryDefinition::PARTITIVE_ENUMERATION_VALUES.join(', ')}"
        end
      end
    end
  end
end
