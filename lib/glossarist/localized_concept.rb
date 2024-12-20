module Glossarist
  class LocalizedConcept < Concept
    attribute :classification, :string
    attribute :review_date, :date
    attribute :review_decision_date, :date
    attribute :review_decision_event, :string
    attribute :review_type, :string
    attribute :entry_status, :string

    alias_method :status=, :entry_status=

    yaml do
      map :classification, to: :classification
      map :review_date, to: :review_date
      map :review_decision_date, to: :review_decision_date
      map :review_decision_event, to: :review_decision_event
      map :review_type, to: :review_type
    end

    def language_code
      data.language_code
    end

    def entry_status
      data.entry_status
    end

    def language_code=(value)
      data.language_code = value
    end

    def entry_status=(value)
      data.entry_status = value
    end
  end
end
