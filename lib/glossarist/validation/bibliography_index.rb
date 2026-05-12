# frozen_string_literal: true

module Glossarist
  module Validation
    class BibliographyIndex
      BIB_ENTRY_KEYS = %w[id ref text anchor].freeze
      private_constant :BIB_ENTRY_KEYS

      attr_reader :entries

      def initialize
        @entries = {}
      end

      def register(anchor, source = nil)
        @entries[normalize_anchor(anchor)] = { anchor: anchor, source: source }
      end

      def resolve?(anchor)
        @entries.key?(normalize_anchor(anchor))
      end

      def anchors
        @entries.keys
      end

      def each_entry(&block)
        @entries.each_value(&block)
      end

      def self.build_from_concepts(concepts, dataset_path: nil,
bibliography_yaml: nil)
        index = new

        concepts.each { |concept| index_concept_sources(index, concept) }

        yaml = bibliography_yaml || read_bibliography_file(dataset_path)
        index_bibliography_yaml(index, yaml) if yaml

        index
      end

      private

      def normalize_anchor(anchor)
        anchor.to_s.gsub(/[ \/:]/, "_").gsub(/__+/, "_")
      end

      class << self
        private

        def read_bibliography_file(dataset_path)
          return nil unless dataset_path

          bib_path = File.join(dataset_path, "bibliography.yaml")
          File.exist?(bib_path) ? File.read(bib_path) : nil
        end

        def index_concept_sources(index, concept)
          concept.localizations.each do |l10n|
            index_l10n_sources(index, l10n)
          end
        end

        def index_l10n_sources(index, l10n)
          data = l10n.data
          return unless data

          register_source_collection(index, data.sources)
          register_source_collection(index,
                                     data.definition&.flat_map(&:sources))
          register_source_collection(index, data.notes&.flat_map(&:sources))
          register_source_collection(index, data.examples&.flat_map(&:sources))
        end

        def register_source_collection(index, sources)
          Array(sources).compact.each { |s| register_source(index, s) }
        end

        def register_source(index, source)
          origin = source.origin
          return unless origin

          register_origin_text(index, origin)
          register_origin_ref(index, origin)
        end

        def register_origin_text(index, origin)
          return unless origin.text && !origin.text.strip.empty?

          index.register(origin.text, origin)
        end

        def register_origin_ref(index, origin)
          return unless origin.source && origin.id

          key = "#{origin.source} #{origin.id}"
          index.register(key, origin)
          index.register(origin.id.to_s, origin)
        end

        def index_bibliography_yaml(index, yaml_content)
          data = YAML.safe_load(yaml_content)
          return unless data.is_a?(Hash) || data.is_a?(Array)

          entries = data.is_a?(Hash) ? data.values : data
          entries.each do |entry|
            next unless entry.is_a?(Hash)

            BIB_ENTRY_KEYS.each do |key|
              val = entry[key]
              index.register(val.to_s, entry) if val && !val.to_s.strip.empty?
            end
          end
        rescue Psych::SyntaxError, Psych::DisallowedClass
          nil
        end
      end
    end
  end
end
