# frozen_string_literal: true

require "relaton"

# Patch Relaton::Registry to handle ArgumentError from incompatible gems
# (e.g. relaton-cen, relaton-ieee) that haven't been updated for
# lutaml-model 0.8's requirement that all attributes have a type.
module RelatonRegistryPatch
  def register_gems
    Relaton::Registry::SUPPORTED_GEMS.each do |b|
      require "#{b}/processor"
      register Kernel.const_get("#{gem_to_module_path(b)}::Processor")
    rescue LoadError, ArgumentError => e
      Relaton::Util.error "backend #{b} not present\n" \
                          "#{e.message}\n#{e.backtrace[0..5].join "\n"}"
    end
  end
end
Relaton::Registry.prepend(RelatonRegistryPatch)

# Patch Relaton::DbCache#grammar_hash to rescue ArgumentError from
# incompatible gems during Relaton::Db initialization.
module RelatonDbCachePatch
  def grammar_hash
    super
  rescue ArgumentError
    nil
  end
end
Relaton::DbCache.prepend(RelatonDbCachePatch)

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
          expected = begin
            Relaton::Registry.instance.by_type(dir.split("/").last)&.grammar_hash
          rescue ArgumentError
            nil
          end
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
