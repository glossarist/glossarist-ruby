# frozen_string_literal: true

module Glossarist
  module V3
    class ImageFile < Lutaml::Model::Collection
      instances :entries, ImageEntry

      key_value do
        map_instances to: :entries
      end

      def self.from_file(path)
        return nil unless File.exist?(path)

        from_yaml(File.read(path))
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
