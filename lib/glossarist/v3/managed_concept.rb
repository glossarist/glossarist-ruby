# frozen_string_literal: true

module Glossarist
  module V3
    # V3 ManagedConcept.
    #
    # V3 storage model:
    # - Concept metadata lives here on the concept (data, related,
    #   dates, sources, status).
    # - N-ary relations (PartitiveRelation, GenericRelation) are
    #   PER-FILE: stored at
    #     relations/<comprehensive-id>/<criterion-slug>.yaml
    #   and loaded via Glossarist::V3::RelationLoader. They are NOT
    #   an inline attribute on the concept.
    #
    # This is the v3 clean break — the bundled format
    # (`partitive_relations: [...]` inline on the concept YAML) is
    # removed. Concept-model removed it without backward compat in
    # commit a62cf85; ruby aligns.
    class ManagedConcept < Glossarist::ManagedConcept
      attribute :data, V3::ManagedConceptData, default: -> { V3::ManagedConceptData.new }
      attribute :related, V3::RelatedConcept, collection: true
      attribute :dates, V3::ConceptDate, collection: true
      attribute :date_accepted, V3::ConceptDate
      attribute :sources, V3::ConceptSource, collection: true

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
      end

      def date_accepted_from_yaml(model, value)
        model.date_accepted = V3::ConceptDate.of_yaml(
          { "date" => value, "type" => "accepted" },
        )
      end
    end
  end
end
