# frozen_string_literal: true

module Glossarist
  module V3
    class ManagedConcept < Glossarist::ManagedConcept
      attribute :data, V3::ManagedConceptData, default: -> { V3::ManagedConceptData.new }
      attribute :related, V3::RelatedConcept, collection: true
      attribute :dates, V3::ConceptDate, collection: true
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
    end
  end
end
