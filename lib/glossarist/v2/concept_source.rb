# frozen_string_literal: true

module Glossarist
  module V2
    class ConceptSource < Glossarist::ConceptSource
      attribute :origin, V2::Citation

      key_value do
        map :origin, to: :origin
        map :status, to: :status
        map :type, to: :type
        map :modification, to: :modification
      end
    end
  end
end
