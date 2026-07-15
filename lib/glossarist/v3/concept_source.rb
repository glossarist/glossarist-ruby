# frozen_string_literal: true

module Glossarist
  module V3
    class ConceptSource < Glossarist::ConceptSource
      attribute :origin, V3::Citation
      attribute :sourced_from, V3::Citation, collection: true

      key_value do
        map :origin, to: :origin
        map :status, to: :status
        map :type, to: :type
        map :modification, to: :modification
        map :sourced_from, to: :sourced_from
      end
    end
  end
end
