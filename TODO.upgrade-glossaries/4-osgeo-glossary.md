# Upgrade Plan: osgeo-glossary

**Repo**: geolexica/osgeo-glossary
**PR**: https://github.com/geolexica/osgeo-glossary/pull/31
**Branch**: `feat/glossarist-gcr-publishing`
**Concepts**: 444 (English only, OSGeo Lexicon)

## Current State

- **Data format**: v2 only (`geolexica-v2/` 444 files). No `concepts/` directory.
- `glossarist package .` picks v2 → packages and validates clean after glossarist fixes.
- **Main branch**: Still uses vocabulary-browser (Node.js) for publishing.
- **PR**: Replaces publish-gcr.yml with `gem install glossarist` + `glossarist package .`.
- Has a `Gemfile` depending on `osgeo-termbase ~> 0.1.0` (may be stale).

## Issues Found

### 1. `register.yaml` has tab indentation (invalid YAML)

`register.yaml` lines 10 and 14 use tab characters instead of spaces:
```yaml
owner:
  entity:
  	name: OSGeo     # ← tab before "name"
```

**Fix**: Replace tabs with spaces in `register.yaml`. GcrPackage now handles this gracefully (returns nil for broken register.yaml), but the file should be fixed.

### 2. No `concepts/` directory

Only has `geolexica-v2/`. The `collections/standards.yaml` file may need attention for proper concept discovery.

## Action Items

1. [x] Fix `GcrPackage` for v2 loading — fixed in glossarist-ruby.
2. [x] Add graceful handling for broken `register.yaml` — fixed in glossarist-ruby.
3. [ ] Fix `register.yaml` tab indentation in the repo.
4. [ ] Release glossarist gem with fixes (needs version >= 2.6.0).
5. [ ] Merge PR #31 to replace vocabulary-browser with glossarist gem.

## Validation Results

```
glossarist package . → Created osgeo-test.gcr (444 concepts)
glossarist validate .gcr → Valid. 0 issues.
```
