# Upgrade Plan: isotc204-glossary

**Repo**: geolexica/isotc204-glossary
**PR**: https://github.com/geolexica/isotc204-glossary/pull/29
**Branch**: `feat/glossarist-gcr-publishing`
**Concepts**: 312 (English only, ISO/TS 14812:2022 ITS vocabulary)

## Current State

- **Data format**: Has BOTH v1 (`concepts/` 312 files) AND v2 (`geolexica-v2/` 312 files)
- v1 validates clean. v2 fails validator (validator only checks v0/v1 format).
- `glossarist package .` picks v2 (preferred) → packages and validates clean after glossarist fixes.
- **PR workflow** (`publish-gcr.yml`): Already on main. Uses `gem install glossarist` + `glossarist package .`.
- PR only adds `TODO.integration/01-gcr-publishing.md` documentation.

## Issues Found

None blocking. Packaging works, validation passes on the generated `.gcr`.

## Action Items

1. [x] Fix `GcrPackage#concept_to_flat_hash` — `LocalizationCollection#each` yields single objects, not `[lang, l10n]` pairs (fixed in glossarist-ruby).
2. [x] Fix `to_h` → `to_hash` for lutaml-model 0.8 compatibility on designations, sources, dates (fixed in glossarist-ruby).
3. [x] Fix `l10n.dates`/`l10n.references` → `l10n.data.dates`/`l10n.data.references` (fixed in glossarist-ruby).
4. [x] Fix `aliases: true` in GCR ZIP validation (fixed in glossarist-ruby).
5. [ ] Release glossarist gem with these fixes (needs version >= 2.6.0).
6. [ ] Merge PR #29 (documentation-only after main already has the workflow).

## Validation Results

```
glossarist package . → Created isotc204-test.gcr (312 concepts)
glossarist validate .gcr → Valid. 0 issues.
```
