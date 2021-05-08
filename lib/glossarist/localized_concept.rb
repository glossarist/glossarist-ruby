module Glossarist
  class LocalizedConcept < Model
    attribute :language_code, :string

    # attribute :terms # TODO

    attribute :notes
    attribute :examples
    attribute :definition
    attribute :authoritative_source

    attribute :entry_status
    attribute :classification

    attribute :review_date
    attribute :review_decision_date
    attribute :review_decision_event

    attribute :date_accepted
    attribute :date_amended
  end
end

