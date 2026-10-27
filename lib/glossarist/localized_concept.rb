module Glossarist
  class LocalizedConcept < Concept
    attribute :classification, :string
    attribute :review_type, :string
    attribute :entry_status, :string

    key_value do
      map :status, to: :entry_status,
                   with: { from: :status_from_yaml, to: :status_to_yaml }
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

    alias_method :status=, :entry_status=

    # Legacy top-level `status` is read only: it fills entry_status when
    # data.entry_status is absent, and is never written back out.
    def status_from_yaml(model, value)
      model.entry_status ||= value
    end

    def status_to_yaml(_model, _doc); end

    def all_sources
      data.all_sources
    end

    def text_content
      data.text_content
    end
  end
end
