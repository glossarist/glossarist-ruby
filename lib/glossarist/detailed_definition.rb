# frozen_string_literal: true

module Glossarist
  class DetailedDefinition < Lutaml::Model::Serializable
    attribute :content, :string
    attribute :sources, ConceptSource, collection: true
    attribute :examples, DetailedDefinition, collection: true,
                                             initialize_empty: true

    key_value do
      map :content, to: :content
      map :sources, to: :sources
      map :examples, to: :examples
    end

    def all_sources
      list = sources.to_a
      examples.each { |example| list.concat(example.all_sources) }
      list
    end

    def text_content
      texts = []
      texts << content if content
      examples.each { |example| texts.concat(example.text_content) }
      texts
    end
  end
end
