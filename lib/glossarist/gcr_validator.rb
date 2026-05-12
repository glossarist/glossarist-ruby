# frozen_string_literal: true

require "zip"

module Glossarist
  class GcrValidator
    def validate(zip_path)
      result = ValidationResult.new

      unless File.exist?(zip_path)
        result.add_error("File not found: #{zip_path}")
        return result
      end

      begin
        zip_entries = Zip::File.open(zip_path) { |zf| zf.entries.to_set(&:name) }
      rescue StandardError => e
        result.add_error("Failed to read ZIP: #{e.message}")
        return result
      end

      unless zip_entries.include?("metadata.yaml")
        result.add_error("Missing metadata.yaml")
        return result
      end

      begin
        context = Validation::Rules::GcrContext.new(zip_path)
      rescue StandardError => e
        result.add_error("Failed to load GCR: #{e.message}")
        return result
      end

      # Collection-level rules (metadata, structure, integrity)
      collection_rules = Validation::Rules::Registry.for_scope(:collection)
      collection_rules.each do |rule|
        next unless rule.applicable?(context)

        rule.check(context).each { |i| result.add_issue(i) }
      end

      # Per-concept rules
      concept_rules = Validation::Rules::Registry.for_scope(:concept)
      context.concepts.each_with_index do |concept, idx|
        fname = concept.data&.id ? "concepts/#{concept.data.id}.yaml" : "concepts/concept-#{idx}.yaml"
        concept_context = Validation::Rules::ConceptContext.new(
          concept, file_name: fname, collection_context: context
        )

        concept_rules.each do |rule|
          next unless rule.applicable?(concept_context)

          rule.check(concept_context).each { |i| result.add_issue(i) }
        end
      end

      result
    end
  end
end
