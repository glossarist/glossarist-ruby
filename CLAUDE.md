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

- **`ManagedConceptCollection`** (`managed_concept_collection.rb`) — top-level enumerable collection of ManagedConcepts. Entry point for loading/saving glossaries via `ConceptManager`.
- **`ManagedConcept`** (`managed_concept.rb`) — a managed concept with `ManagedConceptData` (groups, localized_concepts map, sources), related concepts, dates, and status. Delegates localization via `add_l10n`/`localization(lang)`.
- **`Concept`** (`concept.rb`) — base concept with `ConceptData` (definition, terms/designations, notes, examples, sources, dates, language_code). Parent of `LocalizedConcept`.
- **`LocalizedConcept`** (`localized_concept.rb`) — extends `Concept` with `classification`, `entry_status`, `review_type`.
- **`ConceptData`** (`concept_data.rb`) — the data payload inside `Concept`: definition, terms, examples, notes, sources, non_verb_rep (collection of `NonVerbRep` resource references), language_code (ISO 639), script (ISO 15924), system (ISO 24229 conversion system code). Uses `DetailedDefinition` collections for definition/examples/notes.
- **`ManagedConceptData`** (`managed_concept_data.rb`) — the data payload inside `ManagedConcept`: id, localized_concepts hash (lang_code => uuid), domains (ConceptReference collection — upper concept references replacing the old `groups` string array), sources.

### NonVerbRep (Resource Reference)

`NonVerbRep` (`non_verb_rep.rb`) models non-verbal representations as URI references to external resources (images, tables, formulas), not embedded content. Attributes: `type` (image/table/formula), `ref` (URI — relative path, URN, or URL), `text` (alt text), `sources` (ConceptSource collection).

### ConceptReference & RelatedConcept

- **`ConceptReference`** (`concept_reference.rb`) — a typed reference to another concept. Local refs use `concept_id` alone; external refs use `source` (URN prefix) + `concept_id` or a direct `urn` field. Has `local?`/`external?` predicates. No `to_gcr_hash` or `from_urn` — model-driven architecture uses lutaml-model for serialization; URN construction/parsing belongs in `UrnResolver`.
- **`RelatedConcept`** (`related_concept.rb`) — a concept with a typed relationship. Relationship types cover ISO 10241-1 (deprecates/supersedes/superseded_by/compare/contrast/see), ISO 25964/SKOS (broader/narrower/broader_generic/narrower_generic/broader_partitive/narrower_partitive/broader_instantial/narrower_instantial/equivalent/close_match/broad_match/narrow_match/related_match), ISO 12620/TBX (homograph/false_friend/related_concept/related_concept_broader/related_concept_narrower/sequentially_related_concept/spatially_related_concept/temporally_related_concept), and designation-level (abbreviated_form_for/short_form_for). Types are defined in `config.yml` under `related_concept.type`.

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

### YAML Serialization

- **`ConceptManager`** (`concept_manager.rb`) — handles file I/O. Supports two storage formats:
  1. Separate `concept/` and `localized_concept/` directories (or `localized-concept/` with dashes)
  2. Grouped: concept + localized concepts in a single YAML stream file
- Supports both camelCase and snake_case keys in YAML (e.g., `localizedConcepts` / `localized_concepts`) using `%i[key1 key2]` mapping syntax.
- Also supports V1 format (`concept-*.yaml` files at root level).

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
- **SKOS/RDF models** (`lib/glossarist/rdf/`) — `SkosConcept`, `SkosVocabulary` (ConceptScheme container), `LocalizedLiteral` (language-tagged value), namespace classes.
- TBX, Turtle, JSON-LD, JSONL export all write a single document file; JSON writes per-concept files.

### Dependencies

- `lutaml-model` (~> 0.8.5) — serialization framework (YAML/XML/JSON-LD/Turtle)
- `tbx` — ISO 30042:2019 TBX model classes
- `relaton` (>= 2.0.0, < 3) — bibliography database integration
- `thor` — CLI commands

## Gemfile Notes

The Gemfile overrides relaton gems from git branches for lutaml-model 0.8 compatibility:
- 5 repos use `fix/lutaml-model-0.8` branches (relaton-bib, relaton-iso, relaton-3gpp, relaton-bipm, relaton-bsi)
- 5 repos use `lutaml-integration` branches (relaton-calconnect, relaton-ccsds, relaton-cen, relaton-iec, relaton-itu)
- Released 2.0.0 gems have untyped lutaml-model attributes that fail with 0.8+
- relaton-bib 2.1.0 is released but sub-gems pin `~> 2.0.0`, blocking 2.1.0 adoption until upstream updates constraints
- Remove git overrides once relaton gems release versions with lutaml-model 0.8 support
