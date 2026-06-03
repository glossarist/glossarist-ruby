# frozen_string_literal: true

module Glossarist
  module V3
    class ConceptDocument < Glossarist::ConceptDocument
      attribute :concept, V3::ManagedConcept
      attribute :localizations, V3::LocalizedConcept, collection: true

      yamls do
        sequence do
          map_document 0, to: :concept, type: V3::ManagedConcept
          map_document 1.., to: :localizations, type: V3::LocalizedConcept,
                            collection: true
        end
      end
    end
  end
end
