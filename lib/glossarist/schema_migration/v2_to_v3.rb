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
        # V2 placed `related` inside ManagedConceptData; V3 places it
        # on ManagedConcept itself. Move any data-level related entries
        # up to the concept level. V3::ManagedConceptData no longer
        # serializes `related`, so we don't need to clear the moved-from
        # slot — the V3 output naturally omits it.
        data_related = concept.data&.related
        return step_v2_to_v3_hyperedge_note if data_related.nil? || data_related.empty?

        concept.related ||= []
        concept.related = (concept.related + data_related).uniq
        "3"
      end

      # Hyperedges: V2 has no hyperedge concept. V2's binary
      # `broader_partitive` / `narrower_partitive` edges migrate as
      # `related` entries (see step_v2_to_v3). Hyperedges are a V3-only
      # construct and require no migration logic — concepts upgraded
      # from V2 to V3 simply have no hyperedges.
      def self.step_v2_to_v3_hyperedge_note
        "3"
      end
    end
  end
end
