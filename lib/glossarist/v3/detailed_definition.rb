# frozen_string_literal: true

module Glossarist
  module V3
    class DetailedDefinition < Glossarist::DetailedDefinition
      attribute :sources, V3::ConceptSource, collection: true
      attribute :examples, V3::DetailedDefinition, collection: true,
                                                   initialize_empty: true

      key_value do
        map :content, to: :content
        map :sources, to: :sources
        map :examples, to: :examples
      end
    end
  end
end
