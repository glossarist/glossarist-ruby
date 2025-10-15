module Glossarist
  module Commands
    class ValidateConcepts < Base
      def run
        output_content = []
        concepts = load_concepts(options[:concept_path])
        validate_concepts(concepts, output_content)
        output(output_content)
      end

      def validate_concepts(concepts, output_content) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength
        output_content << "Validate concepts:"
        output_content << "-" * 40

        concepts.each do |concept|
          validation_errors = []
          output_content << "Validating concept: #{concept.id}"

          validate_model(concept, validation_errors)
          validation_errors.flatten!

          if validation_errors.empty?
            output_content << "No validation errors found."
          else
            output_content << "Validation errors found:"
            err_messages = []
            validation_errors.each do |error|
              err_messages << error.to_s
            end
            err_messages.uniq.each do |error|
              output_content << " - #{error}"
            end
          end
        end
        output_content << "-" * 40
      end

      def validate_model(model, validation_errors = []) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength
        case model
        when Lutaml::Model::Serializable
          validation_errors << model.validate
          model.class.attributes.each do |attr_name|
            attr_value = model.send(attr_name.first)
            validate_model(attr_value, validation_errors)
          end
        when Array
          model.each do |item|
            validate_model(item, validation_errors)
          end
        when Hash
          model.each_value do |value|
            validate_model(value, validation_errors)
          end
        end
      end
    end
  end
end
