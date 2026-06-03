# frozen_string_literal: true

module Glossarist
  class BibliographyData < Lutaml::Model::Serializable
    attribute :shortname, :string, default: -> { "bibliography" }
    attribute :entries, BibliographyEntry, collection: true,
                                           initialize_empty: true

    key_value do
      map nil, to: :entries,
               with: { from: :entries_from_hash, to: :entries_to_hash }
    end

    def find(citation_key)
      entries.find { |e| e.citation_key == citation_key }
    end

    def keys
      entries.map(&:citation_key)
    end

    def [](citation_key)
      entry = find(citation_key)
      entry&.data
    end

    def entries_from_hash(model, value)
      return unless value.is_a?(Hash)

      model.entries = value.map do |key, data|
        BibliographyEntry.new(citation_key: key, data: data || {})
      end
    end

    def entries_to_hash(model, doc)
      model.entries.each do |entry|
        doc[entry.citation_key] = entry.data
      end
    end
  end
end
