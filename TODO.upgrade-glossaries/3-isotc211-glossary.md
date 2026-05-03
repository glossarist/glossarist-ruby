# Upgrade Plan: isotc211-glossary

**Repo**: geolexica/isotc211-glossary
**PR**: https://github.com/geolexica/isotc211-glossary/pull/62
**Branch**: `feat/glossarist-gcr-publishing`
**Concepts**: 1,507 (15 languages, ISO/TC 211 terminology)

## Current State

- **Data format**: v2 only (`geolexica-v2/` 1,507 files). No `concepts/` directory.
- `glossarist package .` picks v2 → packages and validates clean after glossarist fixes.
- **Main branch**: Still uses vocabulary-browser (Node.js) for publishing.
- **PR**: Replaces publish-gcr.yml with `gem install glossarist` + `glossarist package .`.

## Issues Found

None blocking. Packaging works, validation passes on the generated `.gcr`.

## Action Items

1. [x] Fix `GcrPackage` for v2 loading (LocalizationCollection iteration, `to_hash`, data accessor paths) — fixed in glossarist-ruby.
2. [x] Fix `aliases: true` in GCR ZIP validation — fixed in glossarist-ruby.
3. [ ] Release glossarist gem with fixes (needs version >= 2.6.0).
4. [ ] Merge PR #62 to replace vocabulary-browser with glossarist gem.

## Validation Results

```
glossarist package . → Created isotc211-test.gcr (1,507 concepts, 15 languages)
glossarist validate .gcr → Valid. 0 issues.
```
