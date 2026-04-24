# frozen_string_literal: true

module Glossarist
  module Collections
    class ConceptSourceCollection < TypedCollection
      instances :sources, ConceptSource
    end
  end
end
