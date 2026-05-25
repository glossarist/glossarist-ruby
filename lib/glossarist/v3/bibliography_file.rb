# frozen_string_literal: true

module Glossarist
  module V3
    class BibliographyFile < Lutaml::Model::Collection
      instances :entries, BibliographyEntry

      key_value do
        map_instances to: :entries
      end

      def self.from_file(path)
        return nil unless File.exist?(path)

        from_yaml(File.read(path))
      end

      def resolve?(anchor)
        entries.any? { |e| e.id == anchor.to_s }
      end

      def [](key)
        entries.find { |e| e.id == key.to_s }
      end
    end
  end
end
