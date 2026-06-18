# frozen_string_literal: true

module Glossarist
  # The bibliography of a dataset, persisted as bibliography.yaml.
  #
  # The file is the *V3 glossarist dataset syntax* for a collection: a YAML
  # mapping with a single key, +bibliography+, whose value is an array of typed
  # BibliographyEntry items. A bibliography is an ordered collection of
  # references, not a keyed map, so each item carries its own +id+ field rather
  # than being indexed by an out-of-band reference string. The single wrapper
  # key keeps the document root a mapping (no stray top-level array).
  #
  # Because the root is a mapping, a single +key_value+ mapping drives both the
  # file (#to_yaml / .from_yaml) and the in-memory store (#to_hash /
  # .from_hash) — no special-case serialization.
  #
  # +shortname+ is internal bookkeeping only: lutaml-store's PackageStore needs
  # a key field to store the bibliography as a single record. It is never
  # serialized — only the +bibliography+ key appears in the file.
  class BibliographyData < Lutaml::Model::Serializable
    attribute :shortname, :string, default: -> { "bibliography" }
    attribute :entries, BibliographyEntry, collection: true,
                                           initialize_empty: true

    key_value do
      map "bibliography", to: :entries
    end

    class << self
      def from_file(path)
        return nil unless File.exist?(path)

        from_yaml(File.read(path, encoding: "utf-8"))
      end
    end

    def find(id)
      entries.find { |e| e.id == id.to_s }
    end

    def keys
      entries.map(&:id)
    end

    def [](id)
      find(id)
    end
  end
end
