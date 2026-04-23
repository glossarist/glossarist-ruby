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

### Core Model Hierarchy

All model classes use `Lutaml::Model::Serializable` for serialization. Key classes:

- **`ManagedConceptCollection`** (`managed_concept_collection.rb`) — top-level enumerable collection of ManagedConcepts. Entry point for loading/saving glossaries via `ConceptManager`.
- **`ManagedConcept`** (`managed_concept.rb`) — a managed concept with `ManagedConceptData` (groups, localized_concepts map, sources), related concepts, dates, and status. Delegates localization via `add_l10n`/`localization(lang)`.
- **`Concept`** (`concept.rb`) — base concept with `ConceptData` (definition, terms/designations, notes, examples, sources, dates, language_code). Parent of `LocalizedConcept`.
- **`LocalizedConcept`** (`localized_concept.rb`) — extends `Concept` with `classification`, `entry_status`, `review_type`.
- **`ConceptData`** (`concept_data.rb`) — the data payload inside `Concept`: definition, terms, examples, notes, sources, language_code. Uses `DetailedDefinition` collections for definition/examples/notes.
- **`ManagedConceptData`** (`managed_concept_data.rb`) — the data payload inside `ManagedConcept`: id, localized_concepts hash (lang_code => uuid), groups, sources.

### Designation (STI-like pattern)

`Designation::Base` (`designation/base.rb`) uses a self-referencing factory pattern (`of_yaml`) that dispatches to subclasses based on `type` field: `Expression`, `Symbol`, `Abbreviation`, `GraphicalSymbol`, `LetterSymbol`. The mapping is in `SERIALIZED_TYPES`.

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

`collections/` contains `BibliographyCollection` (extends `Relaton::Db` for bibliography caching), `AssetCollection`, `Collection` (base enumerable), and `DesignationCollection`.

### Dependencies

- `lutaml-model` (~> 0.8) — serialization framework (YAML/XML)
- `relaton` (>= 2.0.0, < 3) — bibliography database integration
- `thor` — CLI commands (e.g., `glossarist generate_latex`)

## Branch Notes

The `lutaml-model-0.8` branch upgrades from an earlier lutaml-model to 0.8, which requires explicit types on all attributes. Some upstream relaton-* gems (cen, ieee) haven't been updated yet; a compatibility patch is in `bibliography_collection.rb` that prepends `RelatonRegistryPatch` to gracefully skip incompatible backends.
