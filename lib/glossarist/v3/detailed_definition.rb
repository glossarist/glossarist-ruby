# frozen_string_literal: true

module Glossarist
  module V3
    class DetailedDefinition < Glossarist::DetailedDefinition
      attribute :sources, V3::ConceptSource, collection: true

      key_value do
        map :content, to: :content
        map :sources, to: :sources
      end
    end
  end
end
