# frozen_string_literal: true

require_relative "v3/configuration"
require_relative "v3/citation"
require_relative "v3/concept_source"
require_relative "v3/detailed_definition"
require_relative "v3/concept_ref"
require_relative "v3/related_concept"
require_relative "v3/concept_data"
require_relative "v3/localized_concept"
require_relative "v3/managed_concept_data"
require_relative "v3/managed_concept"
require_relative "v3/concept_document"
require_relative "v3/bibliography_entry"
require_relative "v3/bibliography_file"
require_relative "v3/image_entry"
require_relative "v3/image_file"

module Glossarist
  module V3
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
    Configuration.register_model(BibliographyEntry, id: :bibliography_entry)
    Configuration.register_model(BibliographyFile, id: :bibliography_file)
    Configuration.register_model(ImageEntry, id: :image_entry)
    Configuration.register_model(ImageFile, id: :image_file)
  end
end
