module Glossarist
  class LocalizedConcept < Concept
    # Language code should be exactly 3 char long.
    # TODO: use min_length, max_length once added in Lutaml::Model
    attribute :language_code, :string, pattern: /^.{3}$/
    attribute :classification, :string
    attribute :review_date, :date
    attribute :review_decision_date, :date
    attribute :review_decision_event, :string
    attribute :review_type, :string
    attribute :entry_status, :string

    alias_method :status=, :entry_status=

    yaml do
      map :language_code, with: { to: :lang_to_yaml, from: :lang_from_yaml }
      map :classification, to: :classification
      map :review_date, to: :review_date
      map :review_decision_date, to: :review_decision_date
      map :review_decision_event, to: :review_decision_event
      map :review_type, to: :review_type
      map :entry_status, with: { to: :entry_status_to_yaml, from: :entry_status_from_yaml }
    end

    def lang_to_yaml(model, doc)
    end

    def lang_from_yaml(model, value)
      model.language_code = value
    end

    def entry_status_to_yaml(model, doc)
      doc["status"] = model.entry_status if model.entry_status
    end

    def entry_status_from_yaml(model, value)
      model.entry_status = value
    end

    def review_date=(review_date)
      @review_date = review_date
    end

    def review_decision_date=(review_date)
      @review_decision_date = review_date
    end

    def data_hash(model)
      hash = super

      hash["data"].merge!({
        "language_code" => model.language_code,
        "entry_status" => model.entry_status
      }.compact)

      hash
    end
  end
end
