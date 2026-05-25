# frozen_string_literal: true

module Glossarist
  module V3
    class LocalizedConcept < Glossarist::LocalizedConcept
      attribute :data, V3::ConceptData, default: -> { V3::ConceptData.new }
    end
  end
end
