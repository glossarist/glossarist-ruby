require "json-schema"
require "uri"

module Glossarist
  module Commands
    class ValidateSchemas < Base
      def run
        output_content = []
        validate_schemas(options[:concept_path], output_content)
        output(output_content)
      end

      def validate_schemas(concept_path, output_content) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength
        output_content << "Validate schemas:"
        output_content << "-" * 40

        # load concept schemas
        concept_schema, localized_concept_schema = load_concept_schemas

        Dir.glob(concepts_glob(concept_path)) do |filename|
          validation_errors = []
          output_content << "Validating file: #{relative_path(filename)}"

          mixed_hashes = YAML.load_stream(File.read(filename))
          mixed_hashes.each do |hash|
            if hash["data"].nil?
              raise "Invalid Concept v2 YAML: #{relative_path(filename)}"
            end

            schema = localized_concept_schema
            if hash["data"].key?("localized_concepts")
              schema = concept_schema
            end

            result = JSON::Validator.fully_validate(schema, hash)
            validation_errors << result
          end

          validation_errors.flatten!
          if validation_errors.empty?
            output_content << "No validation errors found."
          else
            output_content << "Validation errors found:"

            validation_errors.each do |error|
              output_content << " - #{error}"
            end
          end
        end

        output_content << "-" * 40
      end

      def load_concept_schemas
        schema_path = options[:schema_path]

        # append slash if not present
        schema_path = "#{schema_path}/" if schema_path[-1] != "/"

        schemas = []
        uri = URI.parse(schema_path)

        if uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
          # load schemas from web
          schemas << YAML.safe_load(URI.join(uri, "concept.yaml").open.read)
          schemas << YAML.safe_load(
            URI.join(uri, "localized-concept.yaml").open.read,
          )
        else
          # load schemas from local file system
          if Pathname.new(schema_path).relative?
            schema_path = File.join(Dir.pwd, schema_path)
          end
          schemas << YAML.safe_load(
            File.read(File.join(schema_path, "concept.yaml")),
          )
          schemas << YAML.safe_load(
            File.read(File.join(schema_path, "localized-concept.yaml")),
          )
        end

        schemas
      end
    end
  end
end
