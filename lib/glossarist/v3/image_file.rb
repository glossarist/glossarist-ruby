# frozen_string_literal: true

module Glossarist
  module V3
    # The dataset's images index, persisted as images.yaml.
    #
    # Uses the V3 glossarist dataset syntax for a collection file: a YAML
    # mapping with a single key, +images+, whose value is an array of typed
    # ImageEntry items (no stray top-level array).
    class ImageFile < Lutaml::Model::Serializable
      attribute :entries, ImageEntry, collection: true, initialize_empty: true

      key_value do
        map "images", to: :entries
      end

      class << self
        def from_file(path)
          return nil unless File.exist?(path)

          from_yaml(File.read(path))
        end
      end

      def path_for_anchor(anchor)
        entries.find { |e| e.id == anchor.to_s }&.path
      end

      def anchor_for_path(path)
        entries.find { |e| e.path == path }&.id
      end

      def path?(path)
        entries.any? { |e| e.path == path }
      end
    end
  end
end
