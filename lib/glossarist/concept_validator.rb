# frozen_string_literal: true

module Glossarist
  class ConceptValidator
    attr_reader :path, :errors, :warnings

    def initialize(path)
      @path = path
      @errors = []
      @warnings = []
    end

    def validate_all
      result = ValidationResult.new
      context = Validation::Rules::DatasetContext.new(@path)
      concept_rules = Validation::Rules::Registry.for_scope(:concept)
      file_idx = 0

      ConceptCollector.each_concept(@path) do |concept|
        fname = concept_file_name(concept, file_idx)
        concept_context = Validation::Rules::ConceptContext.new(
          concept, file_name: fname, collection_context: context
        )

        concept_rules.each do |rule|
          next unless rule.applicable?(concept_context)

          rule.check(concept_context).each { |i| result.add_issue(i) }
        end

        file_idx += 1
      end

      if file_idx.zero?
        yaml_files = find_yaml_files
        if yaml_files.any?
          result.add_error("YAML files found but no parseable concepts")
        end
      end

      # Run collection-level rules
      collection_rules = Validation::Rules::Registry.for_scope(:collection)
      collection_rules.each do |rule|
        next unless rule.applicable?(context)

        rule.check(context).each { |i| result.add_issue(i) }
      end

      # Sync legacy arrays for backward compatibility
      @errors = result.errors
      @warnings = result.warnings

      result
    end

    private

    def find_yaml_files
      concepts_dir = if File.directory?(File.join(@path, "concepts"))
                       File.join(@path, "concepts")
                     else
                       @path
                     end
      Dir.glob(File.join(concepts_dir, "*.yaml"))
    end

    def concept_file_name(concept, idx)
      id = concept.data&.id
      id ? "concept-#{id}.yaml" : "concept-#{idx}.yaml"
    end
  end
end
