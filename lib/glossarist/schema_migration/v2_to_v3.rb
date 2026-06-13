# frozen_string_literal: true

module Glossarist
  class SchemaMigration
    module V2ToV3
      def self.migrate_concept(concept, target_version: Glossarist::SCHEMA_VERSION)
        current = concept_version(concept)
        target = target_version.to_s

        return concept if current == target

        max_steps = 5
        max_steps.times do
          break if current == target

          case current
          when "2" then current = step_v2_to_v3(concept)
          else
            raise Errors::Base,
                  "No concept migration step from version #{current}"
          end
        end

        unless current == target
          raise Errors::Base,
                "Migration chain too long or unresolvable"
        end

        concept.schema_version = target
        concept
      end

      def self.concept_version(concept)
        version = concept.schema_version
        return version.to_s if version && !version.to_s.empty?

        ManagedConcept.detect_schema_version(concept)
      end

      def self.step_v2_to_v3(concept)
        if concept.data&.related&.any?
          concept.related ||= []
          concept.related = (concept.related + concept.data.related).uniq
          concept.data.related = []
        end
        "3"
      end
    end
  end
end
