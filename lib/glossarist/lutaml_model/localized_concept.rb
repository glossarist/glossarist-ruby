module Glossarist
  module LutamlModel
    class LocalizedConcept < Concept
      attribute :language_code, :string
      attribute :classification, :string
      attribute :review_date, :date
      attribute :review_decision_date, :date
      attribute :review_decision_event, :string
      attribute :review_type, :string
      attribute :entry_status, :string

      alias_method :status=, :entry_status=

      yaml do
        map :language_code, to: :language_code
        map :classification, to: :classification
        map :review_date, to: :review_date
        map :review_decision_date, to: :review_decision_date
        map :review_decision_event, to: :review_decision_event
        map :review_type, to: :review_type
        map :entry_status, to: :entry_status
      end

      def language_code=(language_code)
        if language_code.is_a?(String) && language_code.length == 3
          @language_code = language_code
        else
          raise Glossarist::InvalidLanguageCodeError.new(code: language_code)
        end
      end
    end
  end
end
