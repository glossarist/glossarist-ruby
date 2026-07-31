# frozen_string_literal: true

module Glossarist
  module V3
    autoload :Configuration, "glossarist/v3/configuration"
    autoload :Citation, "glossarist/v3/citation"
    autoload :ConceptDate, "glossarist/v3/concept_date"
    autoload :ConceptSource, "glossarist/v3/concept_source"
    autoload :DetailedDefinition, "glossarist/v3/detailed_definition"
    autoload :ConceptRef, "glossarist/v3/concept_ref"
    autoload :RelatedConcept, "glossarist/v3/related_concept"
    autoload :HyperedgeMember, "glossarist/v3/hyperedge_member"
    autoload :AbstractHyperedge, "glossarist/v3/abstract_hyperedge"
    autoload :HyperedgeRegistry, "glossarist/v3/hyperedge_registry"
    autoload :HyperedgeIndex, "glossarist/v3/hyperedge_index"
    autoload :PartitiveHyperedge, "glossarist/v3/partitive_hyperedge"
    autoload :PartitiveMember, "glossarist/v3/partitive_member"
    autoload :GenericHyperedge, "glossarist/v3/generic_hyperedge"
    autoload :GenericMember, "glossarist/v3/generic_member"
    autoload :SequentialHyperedge, "glossarist/v3/sequential_hyperedge"
    autoload :SequentialMember, "glossarist/v3/sequential_member"
    autoload :DefinitionType, "glossarist/v3/definition_type"
    autoload :ConceptType, "glossarist/v3/concept_type"
    autoload :ConceptSystemType, "glossarist/v3/concept_system_type"
    autoload :EquivalenceDegree, "glossarist/v3/equivalence_degree"
    autoload :ConceptSystem, "glossarist/v3/concept_system"
    autoload :RelationLoader, "glossarist/v3/relation_loader"
    autoload :HyperedgeWriter, "glossarist/v3/hyperedge_writer"
    autoload :Multiplicity, "glossarist/v3/multiplicity"
    autoload :ConceptData, "glossarist/v3/concept_data"
    autoload :LocalizedConcept, "glossarist/v3/localized_concept"
    autoload :ManagedConceptData, "glossarist/v3/managed_concept_data"
    autoload :ManagedConcept, "glossarist/v3/managed_concept"
    autoload :ConceptDocument, "glossarist/v3/concept_document"

    Configuration.register_model(Citation, id: :citation)
    Configuration.register_model(ConceptDate, id: :concept_date)
    Configuration.register_model(ConceptSource, id: :concept_source)
    Configuration.register_model(DetailedDefinition, id: :detailed_definition)
    Configuration.register_model(ConceptData, id: :concept_data)
    Configuration.register_model(LocalizedConcept, id: :localized_concept)
    Configuration.register_model(ConceptRef, id: :concept_ref)
    Configuration.register_model(RelatedConcept, id: :related_concept)
    # HyperedgeMember and AbstractHyperedge are abstract base classes —
    # they are NOT registered as Lutaml models because they must not be
    # instantiable directly. Concrete leaves (PartitiveHyperedge,
    # GenericHyperedge, PartitiveMember, GenericMember) are registered
    # below and also auto-registered with HyperedgeRegistry.
    Configuration.register_model(PartitiveHyperedge, id: :partitive_hyperedge)
    Configuration.register_model(PartitiveMember, id: :partitive_member)
    Configuration.register_model(GenericHyperedge, id: :generic_hyperedge)
    Configuration.register_model(GenericMember, id: :generic_member)
    Configuration.register_model(SequentialHyperedge, id: :sequential_hyperedge)
    Configuration.register_model(SequentialMember, id: :sequential_member)
    Configuration.register_model(ManagedConceptData, id: :managed_concept_data)
    Configuration.register_model(ManagedConcept, id: :managed_concept)
    Configuration.register_model(ConceptDocument, id: :concept_document)
    Configuration.register_model(ConceptSystem, id: :concept_system)

    # Eager-load concrete hyperedge leaves so HyperedgeRegistry
    # auto-populates via AbstractHyperedge.inherited. Without this,
    # autoload defers leaf definition until first reference, leaving
    # the registry empty at boot.
    PartitiveHyperedge
    GenericHyperedge
    SequentialHyperedge
  end
end
