# frozen_string_literal: true

require "zip"

module Glossarist
  class GcrValidator
    # N-ary relations live in per-file relation store (see
    # Glossarist::V3::RelationLoader), not inside the GCR. For GCR
    # validation, callers can pass a `relations:` hash keyed by
    # concept_id; the validator passes the per-concept list to each
    # concept's context. Without it, relations are not validated
    # here — only the concepts themselves.
    def initialize(on_progress: nil, relations: nil)
      @on_progress = on_progress
      @relations = relations
    end

    def self.validate(zip_path, relations: nil, **opts)
      new(**opts, relations: relations).validate(zip_path)
    end

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

      context, all_concepts = load_gcr_context(zip_path, result)
      return result if all_concepts.nil?

      validate_concepts(context, all_concepts, result)
      validate_collection(context, result)

      result
    end

    private

    def load_gcr_context(zip_path, result)
      context = Validation::Rules::GcrContext.new(zip_path)
      pkg = GcrPackage.load(zip_path)
      [context, pkg.concepts]
    rescue StandardError => e
      result.add_error("Failed to load GCR: #{e.message}")
      [nil, nil]
    end

    def validate_concepts(context, all_concepts, result)
      concept_rules = Validation::Rules::Registry.for_scope(:concept)
      total = all_concepts.length

      all_concepts.each_with_index do |concept, idx|
        context.add_concept(concept)
        concept_context = Validation::Rules::ConceptContext.new(
          concept,
          file_name: concept.data&.id ? "concepts/#{concept.data.id}.yaml" : "concepts/concept-#{idx}.yaml",
          collection_context: context,
          relations: relations_for_concept(concept),
        )

        concept_rules.each do |rule|
          next unless rule.applicable?(concept_context)

          rule.check(concept_context).each { |i| result.add_issue(i) }
        end

        @on_progress&.call(idx + 1, total)
      end
    end

    def relations_for_concept(concept)
      return [] unless @relations

      @relations[concept.data&.id] || []
    end

    def validate_collection(context, result)
      Validation::Rules::Registry.for_scope(:collection).each do |rule|
        next unless rule.applicable?(context)

        rule.check(context).each { |i| result.add_issue(i) }
      end
    end
  end
end
