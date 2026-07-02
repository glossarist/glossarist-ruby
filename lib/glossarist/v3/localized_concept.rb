# frozen_string_literal: true

module Glossarist
  module V3
    class LocalizedConcept < Glossarist::LocalizedConcept
      attribute :data, V3::ConceptData, default: -> { V3::ConceptData.new }

      def date_accepted_from_yaml(model, value)
        return if model.date_accepted

        model.data.dates ||= []
        model.data.dates << V3::ConceptDate.of_yaml(
          { "date" => value, "type" => "accepted" },
        )
      end
    end
  end
end
