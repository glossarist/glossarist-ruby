# frozen_string_literal: true

require "zip"

module Glossarist
  class GcrValidator
    def validate(zip_path) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      result = ValidationResult.new

      unless File.exist?(zip_path)
        result.add_error("File not found: #{zip_path}")
        return result
      end

      begin
        Zip::File.open(zip_path) do |zf|
          unless zf.find_entry("metadata.yaml")
            result.add_error("Missing metadata.yaml")
            return result
          end

          metadata = GcrMetadata.from_yaml(
            zf.find_entry("metadata.yaml").get_input_stream.read,
          )
          validate_metadata(metadata, result)

          concept_entries = zf.entries.select do |e|
            e.name.start_with?("concepts/") && e.name.end_with?(".yaml")
          end
          if concept_entries.empty?
            result.add_error("No concept files found in concepts/")
          end

          concept_entries.each do |entry|
            validate_concept_entry(entry, metadata, result)
          end
        end
      rescue StandardError => e
        result.add_error("Failed to read ZIP: #{e.message}")
      end

      result
    end

    private

    def validate_metadata(metadata, result)
      unless metadata&.concept_count
        result.add_error("metadata.yaml missing required fields (concept_count)")
      end

      unless metadata&.shortname
        result.add_error("metadata.yaml missing shortname")
      end

      unless metadata&.version
        result.add_error("metadata.yaml missing version")
      end
    end

    def validate_concept_entry(entry, metadata, result) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      raw = entry.get_input_stream.read
      doc = ConceptDocument.from_yamls(raw)
    rescue Psych::SyntaxError => e
      result.add_error("#{entry.name}: invalid YAML at line #{e.line}: #{e.message}")
    rescue StandardError => e
      result.add_error("#{entry.name}: parse error: #{e.message}")
    else
      concept = doc.concept
      unless concept&.data&.id
        result.add_error("#{entry.name}: document 0 missing data.identifier")
      end

      localizations = doc.localizations
      if localizations.empty?
        result.add_error("#{entry.name}: expected at least 1 localization document")
      else
        localizations.each_with_index do |l10n, idx|
          unless l10n&.language_code
            result.add_error("#{entry.name}: document #{idx + 1} missing data.language_code")
          end
        end
      end

      validate_concept_uri(entry, concept, metadata, result)
    end

    def validate_concept_uri(entry, concept, metadata, result) # rubocop:disable Metrics/CyclomaticComplexity
      concept_uri = concept&.data&.uri
      template = metadata&.concept_uri_template
      uri_prefix = metadata&.uri_prefix

      if concept_uri.nil? && template.nil? && uri_prefix.nil?
        result.add_warning("#{entry.name}: no concept URI (data.uri) and no concept_uri_template or uri_prefix in metadata")
      end
    end
  end
end
