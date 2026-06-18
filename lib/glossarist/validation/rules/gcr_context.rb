# frozen_string_literal: true

require "zip"

module Glossarist
  module Validation
    module Rules
      class GcrContext
        attr_reader :zip_path

        def initialize(zip_path)
          @zip_path = zip_path
          @accumulated_concepts = []
          @metadata = nil
          @bibliography_index = nil
          @asset_index = nil
          @zip_entries = nil
        end

        def add_concept(concept)
          @accumulated_concepts << concept
          @concept_ids = nil
        end

        def concepts
          @accumulated_concepts
        end

        def concept_ids
          @concept_ids ||= concepts.filter_map { |c| c.data&.id&.to_s }.to_set
        end

        def metadata
          @metadata ||= Zip::File.open(@zip_path) do |zf|
            entry = zf.find_entry("metadata.yaml")
            return nil unless entry

            GcrMetadata.from_yaml(entry.get_input_stream.read)
          end
        end

        def bibliography_index
          @bibliography_index ||= BibliographyIndex.build_from_yaml(
            concepts,
            bibliography_yaml: read_zip_file("bibliography.yaml"),
          )
        end

        def asset_index
          @asset_index ||= AssetIndex.build_from_zip(@zip_path)
        end

        def declared_languages
          metadata&.languages || []
        end

        def actual_languages
          @actual_languages ||= concepts.flat_map do |c|
            c.localizations.map(&:language_code)
          end.compact.uniq.sort
        end

        def zip_entries
          @zip_entries ||= Zip::File.open(@zip_path) do |zf|
            zf.entries.to_set(&:name)
          end
        end

        def localization_index
          {}
        end

        def referenced_l10n_uuids
          Set.new
        end

        def gcr?
          true
        end

        def read_zip_file(name)
          Zip::File.open(@zip_path) do |zf|
            entry = zf.find_entry(name)
            entry&.get_input_stream&.read
          end
        end
      end
    end
  end
end
