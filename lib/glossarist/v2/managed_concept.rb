# frozen_string_literal: true

module Glossarist
  module V2
    class ManagedConcept < Glossarist::ManagedConcept
      attribute :data, V2::ManagedConceptData, default: -> { V2::ManagedConceptData.new }
      attribute :related, V2::RelatedConcept, collection: true
      attribute :sources, V2::ConceptSource, collection: true

      key_value do
        map :data, to: :data
        map :id, with: { to: :identifier_to_yaml, from: :identifier_from_yaml }
        map :identifier,
            with: { to: :identifier_to_yaml, from: :identifier_from_yaml }
        map :related, to: :related
        map :dates, to: :dates
        map %i[date_accepted dateAccepted],
            with: { from: :date_accepted_from_yaml, to: :date_accepted_to_yaml }
        map :status, to: :status
        map :uuid, to: :uuid, with: { from: :uuid_from_yaml, to: :uuid_to_yaml }
        map :sources, to: :sources
      end
    end
  end
end
