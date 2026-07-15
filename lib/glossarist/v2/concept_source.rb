# frozen_string_literal: true

module Glossarist
  module V2
    class ConceptSource < Glossarist::ConceptSource
      attribute :origin, V2::Citation
      attribute :sourced_from, V2::Citation, collection: true

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
