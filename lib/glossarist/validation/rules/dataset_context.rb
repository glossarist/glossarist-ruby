# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class DatasetContext
        attr_reader :path

        def initialize(path)
          @path = File.expand_path(path)
          @concepts = nil
          @bibliography_index = nil
          @asset_index = nil
          @declared_languages = nil
        end

        def concepts
          @concepts ||= ConceptCollector.collect(@path)
        end

        def concept_ids
          @concept_ids ||= concepts.filter_map { |c| c.data&.id&.to_s }.to_set
        end

        def metadata
          nil
        end

        def bibliography_index
          @bibliography_index ||= BibliographyIndex.build_from_concepts(
            concepts, dataset_path: @path
          )
        end

        def asset_index
          @asset_index ||= AssetIndex.build_from_directory(@path)
        end

        def declared_languages
          @declared_languages ||= begin
            reg = load_register_data
            if reg && reg["languages"].is_a?(Array)
              reg["languages"]
            else
              actual_languages
            end
          end
        end

        def actual_languages
          @actual_languages ||= concepts.flat_map do |c|
            c.localizations.map(&:language_code)
          end.compact.uniq.sort
        end

        def localization_index
          @localization_index ||= build_localization_index
        end

        def referenced_l10n_uuids
          @referenced_l10n_uuids ||= concepts.flat_map do |c|
            (c.data.localized_concepts || {}).values
          end.to_set
        end

        def gcr?
          false
        end

        def read_zip_file(_name)
          nil
        end

        private

        def load_register_data
          reg_path = File.join(@path, "register.yaml")
          return nil unless File.exist?(reg_path)

          YAML.safe_load_file(reg_path)
        end

        def build_localization_index
          index = {}
          %w[localized_concept localized-concept].each do |name|
            dir = File.join(@path, "concepts", name)
            next unless File.directory?(dir)

            Dir.glob(File.join(dir, "*.{yaml,yml}")).each do |f|
              uuid = File.basename(f, ".*")
              index[uuid] = f
            end
          end
          index
        end
      end
    end
  end
end
