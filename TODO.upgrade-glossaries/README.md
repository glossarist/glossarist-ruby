# Glossary Repo Upgrade Plans — GCR Packaging Readiness

All four glossary repos depend on glossarist gem fixes from the current branch. A gem release (>= 2.6.0) is required before any PR can merge.

## Summary

| # | Repo | PR | Concepts | Status | Blocking Issues |
|---|------|-----|----------|--------|-----------------|
| 2 | isotc204-glossary | [#29](https://github.com/geolexica/isotc204-glossary/pull/29) | 312 | Ready | Glossarist release |
| 3 | isotc211-glossary | [#62](https://github.com/geolexica/isotc211-glossary/pull/62) | 1,507 | Ready | Glossarist release |
| 4 | osgeo-glossary | [#31](https://github.com/geolexica/osgeo-glossary/pull/31) | 444 | Ready | Glossarist release, fix register.yaml tabs |
| 5 | glossarist-data-iev | [#1](https://github.com/glossarist/glossarist-data-iev/pull/1) | 22,228 | Needs work | entry_status/definition normalization, build.yml Symbol fix |

## Glossarist Fixes Required (this branch)

All fixed locally, need gem release:

1. `GcrPackage#concept_to_flat_hash`: `LocalizationCollection#each` yields objects, not `[key, value]` pairs → use `each_value`.
2. `to_h` removed in lutaml-model 0.8 → use `to_hash` for designations, sources, dates.
3. `l10n.dates`/`l10n.references` → `l10n.data.dates`/`l10n.data.references` (not delegated).
4. `aliases: true` missing in GCR ZIP validation YAML loading.
5. `Symbol` not permitted in `collect_v1_concepts` YAML loading.
6. Broken `register.yaml` should not crash packaging → rescue `Psych::SyntaxError`.

## Glossarist Release Checklist

- [ ] Commit all GcrPackage fixes
- [ ] Run `bundle exec rspec` (409 tests pass)
- [ ] Release glossarist gem via GHA (patch version)
- [ ] Merge glossary PRs in order: isotc204 → isotc211 → osgeo → glossarist-data-iev
