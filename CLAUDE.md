# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

- `bundle install` — install dependencies
- `bundle exec rspec` — run all tests
- `bundle exec rspec spec/unit/citation_spec.rb` — run a single test file
- `bundle exec rspec spec/unit/citation_spec.rb:12` — run a single test by line number
- `bundle exec rake` — runs `bundle exec rspec` (default rake task)
- `bundle exec rubocop` — lint

## Architecture

Glossarist is a Ruby gem implementing the [Glossarist concept model](https://github.com/glossarist/concept-model) (ISO 10241-1). It provides classes for managing terminology glossaries with multi-language support, serialization to/from YAML, and bibliography integration via Relaton.

All model classes use `Lutaml::Model::Serializable` for serialization.

### Core Model Hierarchy

- **`ManagedConceptCollection`** (`managed_concept_collection.rb`) — legacy enumerable collection of ManagedConcepts. File loading delegates to GlossaryStore via `#load_from_files`; the class is retained as an in-memory accumulator for `STS::Importer` and the legacy `ConceptSet` path. New callers should use GlossaryStore directly.
- **`ManagedConcept`** (`managed_concept.rb`) — a managed concept with `ManagedConceptData` (groups, localized_concepts map, sources), related concepts, dates, and status. Delegates localization via `add_l10n`/`localization(lang)`.
- **`Concept`** (`concept.rb`) — base concept with `ConceptData` (definition, terms/designations, notes, examples, sources, dates, language_code). Parent of `LocalizedConcept`.
- **`LocalizedConcept`** (`localized_concept.rb`) — extends `Concept` with `classification`, `entry_status`, `review_type`.
- **`ConceptData`** (`concept_data.rb`) — the data payload inside `Concept`: definition, terms, examples, notes, sources, non_verb_rep (collection of `NonVerbRep` resource references), language_code (ISO 639), script (ISO 15924), system (ISO 24229 conversion system code). Uses `DetailedDefinition` collections for definition/examples/notes.
- **`ManagedConceptData`** (`managed_concept_data.rb`) — the data payload inside `ManagedConcept`: id, localized_concepts hash (lang_code => uuid), domains (ConceptReference collection — terminological domain references), tags (string collection — organizational tags for grouping/filtering, not rendered as domains), sources.

### NonVerbRep (Resource Reference)

`NonVerbRep` (`non_verb_rep.rb`) models non-verbal representations as URI references to external resources (images, tables, formulas), not embedded content. Attributes: `type` (image/table/formula), `ref` (URI — relative path, URN, or URL), `text` (alt text), `sources` (ConceptSource collection).

### ConceptReference & RelatedConcept

- **`ConceptReference`** (`concept_reference.rb`) — a typed reference to another concept. Local refs use `concept_id` alone; external refs use `source` (URN prefix) + `concept_id` or a direct `urn` field. Has `local?`/`external?` predicates. No `to_gcr_hash` or `from_urn` — model-driven architecture uses lutaml-model for serialization; URN construction/parsing belongs in `UrnResolver`.
- **`RelatedConcept`** (`related_concept.rb`) — a concept with a typed relationship. Relationship types cover ISO 10241-1 (deprecates/supersedes/superseded_by/compare/contrast/see), ISO 25964/SKOS (broader/narrower/broader_generic/narrower_generic/broader_partitive/narrower_partitive/broader_instantial/narrower_instantial/equivalent/close_match/broad_match/narrow_match/related_match), ISO 12620/TBX (homograph/false_friend/related_concept/related_concept_broader/related_concept_narrower/sequentially_related_concept/spatially_related_concept/temporally_related_concept), and designation-level (abbreviated_form_for/short_form_for). Types are defined in `config.yml` under `related_concept.type`.

#### V3 `related` placement (MECE)

In V3, `related` lives **only** on `V3::ManagedConcept#related`.
`V3::ManagedConceptData` does NOT declare or serialize `related`.
V2 placed `related` inside data; the `SchemaMigration::V2ToV3#step_v2_to_v3`
migration moves any data-level entries up to the concept level. The
V3 output never carries `related` at the data level.

This consolidation closes the legacy trap where writing to
`data.related` bypassed `ManagedConcept.detect_schema_version` (which
keys off `concept.related`).

### PartitiveHyperedge (V3 only)

`PartitiveHyperedge` (`v3/partitive_hyperedge.rb`) — a one-to-many partitive decomposition. One comprehensive concept is related to one or more parts as a SINGLE relationship. Captures invariants that binary `RelatedConcept` edges cannot:

- which comprehensive owns which parts (set membership)
- diagram notation flags (`PluralityMarker`: `double`, `dashed`)
- enumeration completeness (`PartitiveEnumeration`: `closed`, `open`)

Wired into `V3::ManagedConcept#partitive_hyperedges`. NOT on `ManagedConceptData` (relationships live at the concept level for MECE consistency with `related`).

Enum values are SSOT-loaded from `config.yml` via `GlossaryDefinition::PARTITIVE_ENUMERATION_VALUES` and `PLURALITY_MARKER_VALUES`. The `values:` option on each attribute documents the enum; the model's `initialize` override enforces them at construction (lutaml-model 0.8.17 does not enforce `values:` on assignment). Construction also rejects empty comprehensive, empty parts, self-loops, and duplicate marker values.

Semantic checks (defaulted-enumeration warning, defensive walk) live in `Validation::Rules::PartitiveHyperedgeRule` (auto-registered by `Validation::Rules`).

RDF emission: `Rdf::GlossHyperedge` view class (per-hyperedge `gloss:PartitiveHyperedge` subject with `gloss:comprehensive`, `gloss:part+`, `gloss:enumeration`, `gloss:hasPluralityMarker*`, `gloss:hyperedgeContent?`), wired into `Transforms::ConceptToGlossTransform` and emitted as `gloss:hasHyperedge` link from `GlossConcept`.

Binary `broader_partitive`/`narrower_partitive` `RelatedConcept` edges and `PartitiveHyperedge` coexist — no automatic consolidation. See `concept-model/TODO.hyperedge/00-design-overview.md`.

### Reference Resolution

- **`ReferenceExtractor`** (`reference_extractor.rb`) — extracts `ConceptReference` and `AssetReference` objects from `{{...}}` mentions and `image::...[]` references in concept text fields.
- **`ReferenceResolver`** (`reference_resolver.rb`) — resolves references via adapter chain (local → package → remote). Supports route overrides for URI remapping.
- **`UrnResolver`** (`urn_resolver.rb`) — converts URNs to canonical HTTP URLs (IEC Electropedia, ISO OBP). Extensible via `register_scheme`. All URN construction/parsing logic lives here, not in the model.

### UUID Generation

Concepts use deterministic UUID v5 (SHA-1) derived from their serialized YAML content and the OID namespace (`Utilities::UUID`). This means a concept's UUID is stable across sessions as long as its data doesn't change.

### Designation (STI-like pattern)

`Designation::Base` (`designation/base.rb`) uses a self-referencing factory pattern (`of_yaml`) that dispatches to subclasses based on `type` field: `Expression`, `Symbol`, `Abbreviation`, `GraphicalSymbol`, `LetterSymbol`. The bi-directional mapping is in `SERIALIZED_TYPES` (`designation.rb`).

Designation inheritance hierarchy (MECE):
- **Base** — `designation`, `normative_status` (preferred/admitted/deprecated/superseded), `geographical_area`, `type`, `language`/ISO 639, `script`/ISO 15924, `system`/ISO 24229, `international`, `absent`, `pronunciation` (collection of `Pronunciation` objects), `sources` (collection of `ConceptSource` — per-designation sources per ISO 10241-1 §6.8), `term_type` (ISO 12620 term type classification — 24 values from `config.yml`), `related` (collection of `RelatedConcept` — designation-level intra-entry relationships: `abbreviated_form_for`, `short_form_for`)
- **Expression < Base** — `prefix`, `usage_info`, `field_of_application` (IEC "specific use"), `grammar_info`
- **Abbreviation < Expression** — abbreviation type booleans (`acronym`, `initialism`, `truncation`) from `config.yml`
- **Symbol < Base** — (no additional attributes)
- **LetterSymbol < Symbol** — `text`
- **GraphicalSymbol < Symbol** — `text`, `image`

`ConceptData#domain` stores URI references (relative like `section-103-01`, URN like `urn:iec:std:iec:60050-103-01`, or URL like `https://...`) to subject area concepts.

### Dataset Loading

- **`GlossaryStore`** (`glossary_store.rb`) — the dataset abstraction. Backed by `Lutaml::Store::PackageStore`, handles loading/saving from directories and ZIPs, concept CRUD, metadata, bibliography, images, dataset-level non-verbal entities (`#figures`, `#tables`, `#formulas` lazy-loaded from `figures/`/`tables/`/`formulas/` subdirectories), and stats. Format detection is model-driven via `ConceptDocument.for_version`. **All callers that need to load concepts from a dataset should use GlossaryStore.**
- **`ConceptCollector`** (`concept_collector.rb`) — legacy scanner with hand-rolled format detection. No production callers; retained for ABI compatibility. Use GlossaryStore.
- **`ConceptManager`** (`concept_manager.rb`) — legacy file I/O used by `ManagedConceptCollection#load_from_files`. No direct production callers; retained for the legacy collection path. Use GlossaryStore.
- **`ManagedConceptCollection`** (`managed_concept_collection.rb`) — legacy collection. File loading delegates to GlossaryStore; retained as an in-memory accumulator for `STS::Importer`. `ConceptSet` now uses GlossaryStore directly (previously went through this collection).

### YAML Serialization

- Supports both camelCase and snake_case keys in YAML (e.g., `localizedConcepts` / `localized_concepts`) using `%i[key1 key2]` mapping syntax.
- Also supports V1 format (`concept-*.yaml` files at root level).

### V3 Dataset Syntax (collection files are single-key mappings)

A dataset collection file — `bibliography.yaml`, `images.yaml`, and any future
equivalent — is the *V3 glossarist dataset syntax*: a YAML **mapping with a
single wrapper key** whose value is an **array of typed items**. No keyed maps
(indexing items by an out-of-band reference string), and no stray top-level
arrays — the array is always grouped under one named key. Each item carries its
own `id` field. (A keyed bibliography was tried and rejected as wrong — a
bibliography is an ordered collection, not a map, and keying forced the entry to
degenerate into `citation_key` + an untyped `data` hash. A bare top-level array
was also rejected — the user does not want stray arrays at the document root.)

Canonical models: `BibliographyData` + typed `BibliographyEntry`;
`V3::ImageFile` + `V3::ImageEntry`. `bibliography.yaml` wraps its entries under a
single `bibliography:` key. Because the root is a mapping, one `key_value` map
(`map "bibliography", to: :entries`) drives both the file (`to_yaml`/`from_yaml`)
and the in-memory store (`to_hash`/`from_hash`) — no overrides, no nested
Collection, no `YAML.safe_load`. `BibliographyData#shortname` is the
PackageStore record key only — never serialized. Documentation lives in
`README.adoc` (`== Bibliography`); this note is internal guidance, not user docs.

The remaining `map nil` keyed patterns live only in the **V1 legacy adapters**
(`v1/register.rb`, `v1/concept.rb`), which are intentional passthroughs for old
IEV-format datasets — do not "fix" them; that would break reading V1 data.

### Configuration & Extensibility

- **`Config`** (`config.rb`) — singleton that holds registered classes for `:localized_concept` and `:managed_concept`. Allows swapping implementations via `register_class`.
- **`GlossaryDefinition`** (`glossary_definition.rb`) — loads enum values (concept statuses, source types, etc.) from `config.yml`.
- A `glossarist.yaml` file in the working directory can register extension attributes.

### Collections

Custom collection classes in `collections/` extend `Lutaml::Model::Collection`:
- **`LocalizationCollection`** — keyed by `language_code`, used for `ManagedConceptData#localizations`.
- **`DetailedDefinitionCollection`**, **`ConceptSourceCollection`** — typed collections for ConceptData fields.
- **`BibliographyCollection`** — extends `Relaton::Db` for bibliography caching with cache version checking.
- **`AssetCollection`**, **`Collection`** (base enumerable), **`DesignationCollection`**.

### GCR Packaging

Three classes handle glossary concept registry (GCR) ZIP packages:
- **`GcrPackage`** (`gcr_package.rb`) — creates/loads/validates ZIP archives containing `metadata.yaml`, `register.yaml`, and `concepts/*.yaml` entries.
- **`GcrMetadata`** (`gcr_metadata.rb`) — package metadata (shortname, version, languages, statistics). Built from concepts via `GcrMetadata.from_concepts`.
- **`GcrStatistics`** (`gcr_statistics.rb`) — computes stats (total concepts, languages, concepts by status) from concept data.
- **`SchemaMigration`** (`schema_migration.rb`) — migrates concepts from v0 (legacy IEV format) to v1, normalizing definitions, dates, entry statuses, and extracting inline references.
- **`ValidationResult`** (`validation_result.rb`) — simple errors/warnings container for package validation.

### CLI

The `exe/glossarist` executable uses Thor. Commands:
- `generate_latex` — converts concepts to LaTeX glossary entries
- `package` — creates `.gcr` ZIP archives with optional compiled formats (`--compiled-formats tbx,jsonld,turtle,jsonl`)
- `export` — exports concepts in json/tbx/jsonld/turtle/jsonl formats
- `validate` — validates datasets and `.gcr` files
- `upgrade` — migrates datasets to current schema version

### Export Transforms

- **`ConceptToTbxTransform`** (`transforms/concept_to_tbx_transform.rb`) — converts ManagedConcept to TBX-XML using the tbx gem (ISO 30042:2019). Produces `Tbx::ConceptEntry` per concept or `Tbx::Document` for full export.
- **`ConceptToSkosTransform`** (`transforms/concept_to_skos_transform.rb`) — converts ManagedConcept to SKOS RDF using `Glossarist::Rdf::SkosConcept`. Has `transform` (single) and `transform_document` (batch, returns `SkosVocabulary`). Produces JSON-LD and Turtle via the unified `rdf` DSL.
- **`ConceptToGlossTransform`** (`transforms/concept_to_gloss_transform.rb`) — converts ManagedConcept and dataset-level non-verbal entities to ontology-faithful RDF using `Glossarist::Rdf::Gloss*` view classes. `transform_document(concepts, figures:, tables:, formulas:)` and `to_turtle`/`to_jsonld` accept figures/tables/formulas kwargs (backward compatible — empty defaults). Uses a `DESIGNATION_BUILDERS` registry keyed by exact Designation subclass (OCP) instead of a case/when switch.
- **SKOS/RDF models** (`lib/glossarist/rdf/`) — `GlossConcept`, `GlossLocalizedConcept`, `GlossDesignation` and subclasses, `GlossFigure`/`GlossTable`/`GlossFormula`/`GlossFigureImage` (dataset-level non-verbal entities per concept-model v3.1.0 K1/K2 shapes), `SkosConcept`, `SkosVocabulary`, `LocalizedLiteral`, namespace classes. `EmitsExtraTriples` is autoloaded from `lutaml_ext.rb` via the immediate parent namespace file (`rdf.rb`); `LutamlTurtleTransformExt` is prepended into `Lutaml::Turtle::Transform` so the framework asks each instance for extra triples.
- TBX, Turtle, JSON-LD, JSONL export all write a single document file; JSON writes per-concept files.

### Dependencies

- `lutaml-model` (~> 0.8.5) — serialization framework (YAML/XML/JSON-LD/Turtle)
- `tbx` — ISO 30042:2019 TBX model classes
- `relaton` (>= 2.0.0, < 3) — bibliography database integration
- `thor` — CLI commands

## Dependencies

- `relaton` (>= 2.0.0, < 3) — bibliography database integration. Upstream
  shipped 2.1.0 with lutaml-model 0.8 compatibility, so the historical
  git-branch overrides are no longer needed and the Gemfile pins the
  released gem directly.
- `lutaml-model` (~> 0.8.5), `lutaml-store` (~> 0.2.0) — serialization
  framework (YAML/XML/JSON-LD/Turtle) and package store.
- `tbx` — ISO 30042:2019 TBX model classes.
- `thor` — CLI commands.
- `rdf-turtle` (~> 3.3), `shacl` (~> 0.4) — Turtle emission + SHACL
  validation against vendored concept-model shapes.

## SchemaMigration module split

`SchemaMigration` is a thin facade over three single-concern modules:

- `SchemaMigration::V0ToV1` — hash-to-hash transform (IEV legacy YAML → V1 shape). Single `#migrate` entry point.
- `SchemaMigration::V2ToV3` — model-to-model transform (`V2::ManagedConcept` → `V3::ManagedConcept`). Class methods `migrate_concept` / `concept_version`.
- `SchemaMigration::CliPipeline` — file I/O + dispatch + output writing for `glossarist upgrade`. Single `#run` entry point; output can be a directory of YAML files or a `.gcr` ZIP package.

The facade preserves the historical class-method API (`SchemaMigration.new`, `.migrate_concept`, `.concept_version`, `.upgrade_directory`) so existing callers don't break. Adding V3→V4 later means adding a new module under `SchemaMigration::`, not editing these.

## Schema Version Subclasses Are NOT Duplication

V2 and V3 namespace classes (e.g. `V2::ManagedConceptData`, `V3::ManagedConceptData`) exist because each schema version has its own `key_value` mapping and its own type references (`V2::LocalizedConcept` vs `V3::LocalizedConcept`). These are version-specific serialization adapters at a **real seam** — two adapters justifies the seam.

Do not attempt to "parameterize" or "collapse" these into the base class:

- **OCP**: Adding a new schema version = adding a new subclass, not modifying the base. This is the pattern working as intended.
- **lutaml-model DSL is class-level**: `attribute` and `key_value` mappings are declarative DSL invoked at class definition time. They cannot be meaningfully "parameterized" at the instance level without metaprogramming (`Class.new`), which is worse than the current clear, declarative pattern.
- **Structural similarity ≠ accidental duplication**: The fact that V2 and V3 `ManagedConceptData` look similar is because V3 evolved from V2. Their `localizations_from_yaml` callbacks differ in which class they instantiate, their `key_value` mappings differ in which fields are mapped, and V2 has custom `related` handling that V3 doesn't. These differences will diverge further as the schemas evolve.
- **Three similar lines is better than a wrong abstraction**: The global instruction applies directly here.

## Architectural Review Findings (2026-06-10)

### Valid deepening opportunities

See `TODO.improve/` for detailed plans.

1. **Phase out `ManagedConceptCollection` entirely** — `ConceptSet` now loads via GlossaryStore directly (PR #212). The only remaining user is `STS::Importer`, which uses the collection as an in-memory accumulator after loading via GlossaryStore/GcrPackage. Migrating STS::Importer to a plain Array would close the legacy chapter.

### Rejected candidates (do not re-suggest)

- **Collapse V2/V3 ManagedConceptData** — Version subclasses are a real seam, not duplication. See "Schema Version Subclasses Are NOT Duplication" above.
- **Extract validation reporter from CLI::ValidateCommand** — 159 lines of terminal formatting in a CLI command is normal. Creating 4 reporter classes to replace a 3-way case statement (where 2 branches are 1 line each) is premature abstraction. CLI commands are leaf nodes, not extension points.
- **Refactor ConceptToGlossTransform** — The transform is already deep (3 public methods, 343 lines of implementation). Moving mapping to domain models would violate model-driven by leaking RDF knowledge into the domain layer. Using lutaml-model views can't handle the type dispatching and URI construction the transform does. The module has locality (all mapping in one place) and leverage (one interface, N callers).
