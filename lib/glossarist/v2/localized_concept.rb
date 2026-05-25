# frozen_string_literal: true

module Glossarist
  module V2
    class LocalizedConcept < Glossarist::LocalizedConcept
      attribute :data, V2::ConceptData, default: -> { V2::ConceptData.new }
    end
  end
end
