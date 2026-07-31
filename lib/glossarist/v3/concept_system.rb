# frozen_string_literal: true

module Glossarist
  module V3
    # ConceptSystem — first-class concept system entity per ISO 12620 A.7.
    #
    # Promotes the previously-implicit concept system (domains + tags +
    # relation graph) to an explicit first-class entity. Per-file at
    # `concept-systems/<id>.yaml`.
    #
    # A ConceptSystem carries:
    #   - id: stable identifier
    #   - name: localized human-readable name
    #   - type: ConceptSystemType (generic / partitive / sequential /
    #     associative / mixed)
    #   - members: ConceptRefs of concepts in the system
    #   - hyperedges: references to per-file hyperedge $ids
    #   - root_concepts: top-level concepts (no superordinate)
    #   - sources, status: provenance and lifecycle
    #
    # See docs/design/concept-systems.md in concept-model repo.
    class ConceptSystem < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :name, :hash
      attribute :type, :string,
                values: Glossarist::V3::ConceptSystemType::VALUES
      attribute :domain, ConceptRef
      attribute :purpose, :hash
      attribute :members, ConceptRef, collection: true
      attribute :hyperedges, :string, collection: true
      attribute :root_concepts, ConceptRef, collection: true
      attribute :sources, ConceptSource, collection: true
      attribute :status, :string

      key_value do
        map :id, to: :id
        map :name, to: :name
        map :type, to: :type
        map :domain, to: :domain
        map :purpose, to: :purpose
        map :members, to: :members
        map :hyperedges, to: :hyperedges
        map :root_concepts, to: :root_concepts, with: { from: :root_concepts_from, to: :root_concepts_to }
        map :sources, to: :sources
        map :status, to: :status
      end

      def validate!
        validate_id!
        validate_name!
        validate_type!
        validate_members!
        self
      end

      def generic? = type == ConceptSystemType::GENERIC
      def partitive? = type == ConceptSystemType::PARTITIVE
      def sequential? = type == ConceptSystemType::SEQUENTIAL
      def associative? = type == ConceptSystemType::ASSOCIATIVE
      def mixed? = type == ConceptSystemType::MIXED

      private

      def validate_id!
        return if id && !id.to_s.empty?

        raise ArgumentError, "ConceptSystem#id must be non-empty"
      end

      def validate_name!
        return if name.is_a?(Hash) && !name.empty?

        raise ArgumentError, "ConceptSystem#name must be a non-empty hash (localized)"
      end

      def validate_type!
        return if ConceptSystemType::VALUES.include?(type)

        raise ArgumentError,
              "ConceptSystem#type #{type.inspect} invalid; " \
              "must be one of #{ConceptSystemType::VALUES.join(', ')}"
      end

      def validate_members!
        return if members.is_a?(Array) && members.length.positive?

        raise ArgumentError, "ConceptSystem#members must have at least one entry"
      end

      def root_concepts_from(model, value)
        model.root_concepts = Array(value).map do |entry|
          entry.is_a?(ConceptRef) ? entry : ConceptRef.new(entry || {})
        end
      end

      def root_concepts_to(model, _doc)
        model.root_concepts&.map(&:to_hash)
      end
    end
  end
end
