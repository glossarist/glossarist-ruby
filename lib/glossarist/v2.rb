# frozen_string_literal: true

require_relative "v2/configuration"
require_relative "v2/citation"
require_relative "v2/concept_source"
require_relative "v2/detailed_definition"
require_relative "v2/concept_ref"
require_relative "v2/related_concept"
require_relative "v2/concept_data"
require_relative "v2/localized_concept"
require_relative "v2/managed_concept_data"
require_relative "v2/managed_concept"
require_relative "v2/concept_document"

module Glossarist
  module V2
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
