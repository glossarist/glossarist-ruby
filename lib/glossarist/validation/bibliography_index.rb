# frozen_string_literal: true

module Glossarist
  module Validation
    class BibliographyIndex
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

      def each_entry(&)
        @entries.each_value(&)
      end

      def self.build_from_concepts(concepts, dataset_path: nil)
        index = new

        concepts.each { |concept| index_concept_sources(index, concept) }
        index_bibliography_file(index, dataset_path)
        index_images_file(index, dataset_path)

        index
      end

      def self.build_from_yaml(concepts, bibliography_yaml: nil,
images_yaml: nil)
        index = new

        concepts.each { |concept| index_concept_sources(index, concept) }
        index_bib_from_yaml_string(index, bibliography_yaml)
        index_images_from_yaml_string(index, images_yaml)

        index
      end

      private

      def normalize_anchor(anchor)
        anchor.to_s.gsub(/[ \/:]/, "_").gsub(/__+/, "_")
      end

      class << self
        private

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
          ref = origin.ref
          return unless ref&.source && !ref.source.strip.empty?

          index.register(ref.source, origin)
        end

        def register_origin_ref(index, origin)
          ref = origin.ref
          return unless ref&.source && ref.id

          key = "#{ref.source} #{ref.id}"
          index.register(key, origin)
          index.register(ref.id.to_s, origin)
        end

        def index_bibliography_file(index, dataset_path)
          return unless dataset_path

          bib = BibliographyData.from_file(
            File.join(dataset_path, "bibliography.yaml"),
          )
          return unless bib

          Array(bib.entries).each do |entry|
            next unless entry&.id

            index.register(entry.id, entry)
            index.register(entry.reference, entry) if entry.reference
          end
        rescue StandardError
          nil
        end

        def index_images_file(index, dataset_path)
          return unless dataset_path

          images = V3::ImageFile.from_file(
            File.join(dataset_path, "images.yaml"),
          )
          return unless images

          Array(images.entries).each do |entry|
            next unless entry&.id

            index.register(entry.id, entry)
          end
        rescue StandardError
          nil
        end

        def index_bib_from_yaml_string(index, yaml_content)
          return unless yaml_content

          bib = BibliographyData.from_yaml(yaml_content)
          bib.entries.each do |entry|
            index.register(entry.id, entry)
            index.register(entry.reference, entry) if entry.reference
          end
        rescue StandardError
          nil
        end

        def index_images_from_yaml_string(index, yaml_content)
          return unless yaml_content

          images = V3::ImageFile.from_yaml(yaml_content)
          images.entries.each { |entry| index.register(entry.id, entry) }
        rescue StandardError
          nil
        end
      end
    end
  end
end
