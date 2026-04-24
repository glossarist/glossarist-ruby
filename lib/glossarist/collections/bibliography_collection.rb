# frozen_string_literal: true

require "relaton"

module Glossarist
  module Collections
    class BibliographyCollection < Relaton::Db
      def initialize(_concepts, global_cache, local_cache)
        @version_mismatch = check_cache_version(local_cache) ||
                            check_cache_version(global_cache)
        super(global_cache, local_cache)
      end

      def fetch_all(...)
        raise @version_mismatch if @version_mismatch

        super
      end

      private

      def check_cache_version(path)
        return unless path && File.directory?(path)

        Dir["#{File.expand_path(path)}/*/"].each do |dir|
          version_file = "#{dir}version"
          next unless File.exist?(version_file)

          actual = File.read(version_file, encoding: "utf-8").strip
          expected = Relaton::Registry.instance.by_type(dir.split("/").last)&.grammar_hash
          next if expected.nil? || actual == expected

          return CacheVersionMismatchError.new(dir, expected, actual)
        end

        nil
      end

      def populate_bibliographies(concepts)
        concepts.each do |concept|
          concept.default_lang.sources.each do |source|
            next if source.origin.text.nil?

            fetch(source.origin.text)
          end
        end
      end
    end
  end
end
