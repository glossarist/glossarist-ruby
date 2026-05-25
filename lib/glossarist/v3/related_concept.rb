# frozen_string_literal: true

module Glossarist
  module V3
    class RelatedConcept < Glossarist::RelatedConcept
      attribute :ref, V3::ConceptRef

      key_value do
        map :content, to: :content
        map :type, to: :type
        map :ref, to: :ref
      end
    end
  end
end
