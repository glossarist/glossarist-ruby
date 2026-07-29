# frozen_string_literal: true

module Glossarist
  module V3
    # V3 ManagedConcept.
    #
    # V3 storage model:
    # - Concept metadata lives here on the concept (data, related,
    #   dates, sources, status).
    # - Hyperedges (PartitiveHyperedge, GenericHyperedge) are PER-FILE:
    #   stored at relations/<comprehensive-id>/<criterion-slug>.yaml
    #   and loaded via Glossarist::V3::RelationLoader. They are NOT
    #   serialized inline on the concept YAML.
    #
    # This is the v3 clean break — the bundled format
    # (`partitive_relations: [...]` inline on the concept YAML) is
    # removed. Concept-model removed it without backward compat in
    # commit a62cf85; ruby aligns.
    #
    # #relations is the unified accessor. The list is populated by
    # callers (GlossaryStore#relations_for, RelationLoader, direct
    # construction). NO typed projections — callers filter:
    #
    #   concept.relations.select { |r| r.is_a?(PartitiveHyperedge) }
    #   concept.relations.select { |r| r.comprehensive.id == my_id }
    class ManagedConcept < Glossarist::ManagedConcept
      attribute :data, V3::ManagedConceptData, default: -> { V3::ManagedConceptData.new }
      attribute :related, V3::RelatedConcept, collection: true
      attribute :dates, V3::ConceptDate, collection: true
      attribute :date_accepted, V3::ConceptDate
      attribute :sources, V3::ConceptSource, collection: true

      # Unified hyperedge accessor. NOT serialized (per-file storage);
      # populated externally by GlossaryStore / RelationLoader.
      attribute :relations, V3::AbstractHyperedge, collection: true

      key_value do
        map :data, to: :data
        map :related, to: :related
        map :dates, to: :dates
        map %i[date_accepted dateAccepted],
            with: { from: :date_accepted_from_yaml, to: :date_accepted_to_yaml }
        map :status, to: :status
        map %i[id uuid], to: :uuid,
                         with: { from: :uuid_from_yaml, to: :uuid_to_yaml }
        map :schema_version, to: :schema_version
        map :sources, to: :sources
        # relations: intentionally NOT mapped — per-file storage only.
      end

      def date_accepted_from_yaml(model, value)
        model.date_accepted = V3::ConceptDate.of_yaml(
          { "date" => value, "type" => "accepted" },
        )
      end

      # Strict setter — rejects duplicates by identity (type +
      # comprehensive + criterion fingerprint). Adding the same
      # hyperedge twice is always a bug; dedupe hides bugs.
      def relations=(list)
        seen = {}
        Array(list).each do |rel|
          key = hyperedge_identity(rel)
          if seen[key]
            raise ArgumentError,
                  "duplicate hyperedge #{key.inspect} — pass each " \
                  "decomposition once"
          end
          seen[key] = rel
        end
        super(seen.values)
      end

      private

      def hyperedge_identity(rel)
        return rel.object_id.to_s unless rel.is_a?(V3::AbstractHyperedge)

        comp = Glossarist::ConceptRef.qualified_id(rel.comprehensive)
        crit = rel.criterion.is_a?(Hash) ? rel.criterion.sort.to_h : rel.criterion
        "#{rel.class}:#{comp}:#{crit}"
      end
    end
  end
end
