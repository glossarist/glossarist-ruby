# frozen_string_literal: true

module Glossarist
  module V3
    autoload :Configuration, "glossarist/v3/configuration"
    autoload :Citation, "glossarist/v3/citation"
    autoload :ConceptSource, "glossarist/v3/concept_source"
    autoload :DetailedDefinition, "glossarist/v3/detailed_definition"
    autoload :ConceptRef, "glossarist/v3/concept_ref"
    autoload :RelatedConcept, "glossarist/v3/related_concept"
    autoload :ConceptData, "glossarist/v3/concept_data"
    autoload :LocalizedConcept, "glossarist/v3/localized_concept"
    autoload :ManagedConceptData, "glossarist/v3/managed_concept_data"
    autoload :ManagedConcept, "glossarist/v3/managed_concept"
    autoload :ConceptDocument, "glossarist/v3/concept_document"
    autoload :ImageEntry, "glossarist/v3/image_entry"
    autoload :ImageFile, "glossarist/v3/image_file"

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
    Configuration.register_model(ImageEntry, id: :image_entry)
    Configuration.register_model(ImageFile, id: :image_file)
  end
end
