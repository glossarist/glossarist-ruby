# frozen_string_literal: true

module Glossarist
  module V2
    autoload :Configuration, "glossarist/v2/configuration"
    autoload :Citation, "glossarist/v2/citation"
    autoload :ConceptSource, "glossarist/v2/concept_source"
    autoload :DetailedDefinition, "glossarist/v2/detailed_definition"
    autoload :ConceptRef, "glossarist/v2/concept_ref"
    autoload :RelatedConcept, "glossarist/v2/related_concept"
    autoload :ConceptData, "glossarist/v2/concept_data"
    autoload :LocalizedConcept, "glossarist/v2/localized_concept"
    autoload :ManagedConceptData, "glossarist/v2/managed_concept_data"
    autoload :ManagedConcept, "glossarist/v2/managed_concept"
    autoload :ConceptDocument, "glossarist/v2/concept_document"

    Configuration.register_model(Citation, id: :citation)
    Configuration.register_model(ConceptSource, id: :concept_source)
    Configuration.register_model(DetailedDefinition, id: :detailed_definition)
    Configuration.register_model(ConceptData, id: :concept_data)
    Configuration.register_model(LocalizedConcept, id: :localized_concept)
    Configuration.register_model(ConceptRef, id: :concept_ref)
    Configuration.register_model(RelatedConcept, id: :related_concept)
    Configuration.register_model(ManagedConceptData, id: :managed_concept_data)
    Configuration.register_model(ManagedConcept, id: :managed_concept)
    Configuration.register_model(ConceptDocument, id: :concept_document)
  end
end
