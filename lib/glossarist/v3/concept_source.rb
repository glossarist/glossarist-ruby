# frozen_string_literal: true

module Glossarist
  module V3
    class ConceptSource < Glossarist::ConceptSource
      attribute :origin, V3::Citation

      key_value do
        map :origin, to: :origin
        map :status, to: :status
        map :type, to: :type
        map :modification, to: :modification
      end
    end
  end
end
