module Glossarist
  class LocalizedConcept < Concept
    attribute :classification, :string
    attribute :review_type, :string
    attribute :entry_status, :string

    key_value do
      map :classification, to: :classification
      map %i[review_type reviewType], to: :review_type
    end

    NIL_COLLECTION_KEYS = %w[definition examples notes].freeze

    def self.of_yaml(hash, options = {})
      if hash.is_a?(Hash) && (data = hash["data"]).is_a?(Hash)
        NIL_COLLECTION_KEYS.each do |key|
          data[key] = [] if data.key?(key) && data[key].nil?
        end
      end
      super
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
