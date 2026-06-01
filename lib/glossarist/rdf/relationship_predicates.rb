# frozen_string_literal: true

module Glossarist
  module Rdf
    # Canonical data-driven maps for relationship predicates.
    #
    # Each entry maps a relationship type symbol to [namespace_module, predicate_name].
    # These maps drive:
    #   1. Attribute declarations in RDF view classes (one typed collection per predicate)
    #   2. RDF predicate mappings with uri_reference: true
    #   3. Transform grouping logic in ConceptToGlossTransform
    module RelationshipPredicates
      CONCEPT_REL_PREDICATES = {
        broader: [Namespaces::SkosNamespace, :broader],
        narrower: [Namespaces::SkosNamespace, :narrower],
        broader_generic: [Namespaces::IsoThesNamespace, :broaderGeneric],
        narrower_generic: [Namespaces::IsoThesNamespace, :narrowerGeneric],
        broader_partitive: [Namespaces::IsoThesNamespace, :broaderPartitive],
        narrower_partitive: [Namespaces::IsoThesNamespace, :narrowerPartitive],
        broader_instantial: [Namespaces::IsoThesNamespace, :broaderInstantial],
        narrower_instantial: [Namespaces::IsoThesNamespace, :narrowerInstantial],
        equivalent: [Namespaces::SkosNamespace, :exactMatch],
        close_match: [Namespaces::SkosNamespace, :closeMatch],
        broad_match: [Namespaces::SkosNamespace, :broadMatch],
        narrow_match: [Namespaces::SkosNamespace, :narrowMatch],
        related_match: [Namespaces::SkosNamespace, :relatedMatch],
        see: [Namespaces::SkosNamespace, :related],
        deprecates: [Namespaces::GlossaristNamespace, :deprecates],
        supersedes: [Namespaces::GlossaristNamespace, :supersedes],
        superseded_by: [Namespaces::GlossaristNamespace, :supersededBy],
        compare: [Namespaces::GlossaristNamespace, :compares],
        contrast: [Namespaces::GlossaristNamespace, :contrasts],
        sequentially_related_concept: [Namespaces::GlossaristNamespace, :sequentiallyRelated],
        spatially_related_concept: [Namespaces::GlossaristNamespace, :spatiallyRelated],
        temporally_related_concept: [Namespaces::GlossaristNamespace, :temporallyRelated],
        related_concept_broader: [Namespaces::GlossaristNamespace, :relatedConceptBroader],
        related_concept_narrower: [Namespaces::GlossaristNamespace, :relatedConceptNarrower],
      }.freeze

      DESIGNATION_REL_PREDICATES = {
        homograph: [Namespaces::GlossaristNamespace, :hasHomograph],
        false_friend: [Namespaces::GlossaristNamespace, :hasFalseFriend],
        abbreviated_form_for: [Namespaces::GlossaristNamespace, :abbreviatedFormFor],
        short_form_for: [Namespaces::GlossaristNamespace, :shortFormFor],
      }.freeze

      ALL_REL_PREDICATES = CONCEPT_REL_PREDICATES.merge(DESIGNATION_REL_PREDICATES).freeze

      def self.related_targets_by_type(related_concepts, predicate_map)
        targets = group_targets(related_concepts, predicate_map)
        predicate_map.each_key.to_h do |type|
          [:"#{type}_targets", targets[:"#{type}_targets"] || []]
        end
      end

      def self.group_targets(related_concepts, predicate_map)
        valid = valid_related(related_concepts, predicate_map)
        valid
          .group_by { |rc| rc.type.to_sym }
          .transform_values { |rcs| rcs.map { |rc| "concept/#{rc.ref.id}" } }
          .transform_keys { |type| :"#{type}_targets" }
      end

      def self.valid_related(related_concepts, predicate_map)
        Array(related_concepts).select do |rc|
          rc.ref&.id && predicate_map.key?(rc.type.to_sym)
        end
      end
      private_class_method :group_targets, :valid_related
    end
  end
end
