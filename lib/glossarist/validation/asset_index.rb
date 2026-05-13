# frozen_string_literal: true

require "set"
require "zip"

module Glossarist
  module Validation
    class AssetIndex
      IMAGE_TERMS = %w[id ref text anchor].freeze
      private_constant :IMAGE_TERMS

      attr_reader :paths

      def initialize
        @paths = Set.new
      end

      def register(path)
        @paths.add(normalize_path(path))
      end

      def resolve?(path)
        @paths.include?(normalize_path(path))
      end

      def each_path(&block)
        @paths.each(&block)
      end

      def self.build_from_directory(dataset_path)
        index = new
        index_image_files(index, dataset_path)
        index_model_assets(index, dataset_path)
        index
      end

      def self.build_from_zip(zip_path)
        index = new
        index_zip_images(index, zip_path)
        index_zip_concept_assets(index, zip_path)
        index
      end

      private

      def normalize_path(path)
        path.to_s.delete_prefix("/")
      end

      class << self
        private

        def index_image_files(index, dataset_path)
          images_dir = File.join(dataset_path, "images")
          return unless File.directory?(images_dir)

          base = File.expand_path(dataset_path)
          Dir.glob(File.join(images_dir, "**", "*")).each do |file|
            next unless File.file?(file)

            relative = file.sub("#{base}/", "")
            index.register(relative)
          end
        end

        def index_model_assets(index, dataset_path)
          concepts = ConceptCollector.collect(dataset_path)
          index_concept_assets(index, concepts)
        end

        def index_zip_images(index, zip_path)
          Zip::File.open(zip_path) do |zf|
            zf.entries.each do |entry|
              next if entry.name.end_with?("/")
              next unless entry.name.start_with?("images/")

              index.register(entry.name)
            end
          end
        end

        def index_zip_concept_assets(index, zip_path)
          pkg = GcrPackage.load(zip_path)
          index_concept_assets(index, pkg.concepts)
        end

        def index_concept_assets(index, concepts)
          concepts.each do |concept|
            concept.localizations.each do |l10n|
              register_non_verb_rep(index, l10n)
              register_graphical_symbols(index, l10n)
            end
          end
        end

        def register_non_verb_rep(index, l10n)
          Array(l10n.non_verb_rep).each do |nvr|
            next unless nvr.is_a?(NonVerbRep) && nvr.ref && !nvr.ref.strip.empty?

            index.register(nvr.ref.strip)
          end
        end

        def register_graphical_symbols(index, l10n)
          (l10n.data&.terms || []).each do |term|
            next unless term.is_a?(Designation::GraphicalSymbol) && term.image

            index.register(term.image)
          end
        end
      end
    end
  end
end
