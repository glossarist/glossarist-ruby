module Glossarist
  class LocalizedConcept < Concept
    attribute :classification, :string
    attribute :review_type, :string
    attribute :entry_status, :string

    yaml do
      map :classification, to: :classification
      map :review_type, to: :review_type
    end

    alias_method :status=, :entry_status=

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
