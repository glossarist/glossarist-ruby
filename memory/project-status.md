---
name: V2/V3 Namespace Architecture
description: lutaml-model mapping inheritance, model register, V2/V3 namespace design
type: project
---

## lutaml-model mapping inheritance

lutaml-model `key_value` mappings ARE inherited by subclasses — a subclass's `key_value` block merges on top of the parent's mappings, it does NOT replace them. A subclass cannot "unmap" a parent mapping by omitting it.

**Why:** Discovered during V2/V3 namespace implementation. V2::ManagedConcept originally tried to define its own `key_value` block without `related`/`schema_version`/`sources`, but the parent ManagedConcept's mappings for those fields were still active.

**How to apply:** For V2/V3 versioning, only V2::ManagedConceptData needs its own `key_value` (to add `related` mapping inside data). V2::ManagedConcept only overrides the `data` attribute to point to V2::ManagedConceptData — it does NOT need its own `key_value`. V2 is only for deserialization; serialization always uses v3 format via inherited base class mappings.

## Model register (lutaml-model GlobalContext)

Follows the plurimath/mml pattern. Each version has a Configuration module with a unique CONTEXT_ID that extends Glossarist::ContextConfiguration. Models are registered via `Configuration.register_model(ClassName, id: :symbol)`. Type resolution uses `Configuration.resolve_model(:symbol)` which delegates to `Lutaml::Model::GlobalContext.resolve_type`.

**Why:** Enables context-based type resolution instead of hardcoded case/when. Each version's registry is isolated — V2::Configuration resolves `:managed_concept` to V2::ManagedConcept, V3::Configuration resolves to V3::ManagedConcept.

**How to apply:** `ConceptDocument.for_version(version)` looks up the version's Configuration from a VERSION_CONFIGURATION hash and calls `resolve_model(:concept_document)`. Adding a new version requires only a new Configuration module and register_model calls.

## V2 → V3 model-driven migration

V2→V3 migration is fully model-driven: V2::ConceptDocument deserializes v2 YAML (data.related → model), then `SchemaMigration.migrate_concept` promotes `data.related` to `concept.related` and sets schema_version to "3". No hash-based transformation needed — `Steps::V2ToV3` was deleted.

## RDF / JSON-LD / Turtle: version-agnostic

RDF view classes (GlossConcept, GlossLocalizedConcept, etc.) are NOT versioned. They operate on the domain model (ManagedConcept), not on YAML serialization format. schema_version is a YAML metadata field with no SKOS/gloss ontology equivalent. ConceptToGlossTransform takes a domain-model ManagedConcept and produces view-model instances — it is format-agnostic.

**Why:** Whether a concept was loaded from v2 or v3 YAML, the RDF output is identical. The domain model normalizes away format differences.

**How to apply:** No RDF model changes needed for v2/v3. If a future v4 changes the domain model semantics (not just serialization), RDF view classes would need updating.

## README documentation (completed 2026-05-20)

The README.adoc now includes a comprehensive "Schema Versioning (v2 / v3)" section covering:
- V2 vs V3 format differences with YAML examples
- Namespace architecture diagram
- Model register (GlobalContext) usage
- Loading & migration flow diagram
- Usage examples for v2, v3, migration, and RDF export
- "Adding a new schema version" guide (Open/Closed Principle)
