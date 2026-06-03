# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class ModelValidityRule < Base
        def code = "GLS-050"
        def category = :structure
        def severity = "error"
        def scope = :concept

        def applicable?(context)
          context.concept.is_a?(Lutaml::Model::Serializable)
        end

        def check(context)
          validate_recursive(context.concept, context.file_name)
        end

        private

        def validate_recursive(model, location, path = "")
          return [] unless model.is_a?(Lutaml::Model::Serializable)

          issues = collect_model_errors(model, location, path)
          issues.concat(recurse_attributes(model, location, path))
          issues
        end

        def collect_model_errors(model, location, path)
          errors = model.validate
          return [] if errors.empty?

          prefix = path.empty? ? "" : "#{path}: "
          errors.map { |e| issue("#{prefix}#{e}", location: location) }
        end

        def recurse_attributes(model, location, path)
          issues = []

          model.class.attributes.each_key do |name|
            value = model.public_send(name)
            next if value.nil?

            child_path = build_path(path, name)
            issues.concat(validate_collection(value, location, child_path))
          end

          issues
        end

        def validate_collection(value, location, path)
          case value
          when Array
            value.each_with_index.flat_map do |item, idx|
              validate_recursive(item, location, "#{path}[#{idx}]")
            end
          when Lutaml::Model::Serializable
            validate_recursive(value, location, path)
          else
            []
          end
        end

        def build_path(parent, name)
          parent.empty? ? name.to_s : "#{parent}.#{name}"
        end
      end
    end
  end
end
