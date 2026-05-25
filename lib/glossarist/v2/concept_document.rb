# frozen_string_literal: true

module Glossarist
  module V2
    class ConceptDocument < Glossarist::ConceptDocument
      attribute :concept, V2::ManagedConcept
      attribute :localizations, V2::LocalizedConcept, collection: true

      yamls do
        sequence do
          map_document 0, to: :concept, type: V2::ManagedConcept
          map_document 1.., to: :localizations, type: V2::LocalizedConcept,
                                             collection: true
        end
      end
    end
  end
end
